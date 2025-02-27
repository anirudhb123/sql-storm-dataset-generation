WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS movie_rank,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
aggregated_roles AS (
    SELECT
        ci.movie_id,
        rt.role AS role_type,
        COUNT(ci.person_id) AS total_cast
    FROM
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, rt.role
),
movie_info_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(mk.keyword) AS keywords
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY
        m.id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ar.role_type, 'No Role') AS role_type,
    COALESCE(ar.total_cast, 0) AS total_cast,
    r.keyword_count,
    CASE 
        WHEN r.movie_rank <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS ranking_category,
    ARRAY_TO_STRING(mkw.keywords, ', ') AS keywords_list
FROM
    ranked_movies r
LEFT JOIN 
    aggregated_roles ar ON r.movie_id = ar.movie_id
LEFT JOIN 
    movie_info_with_keywords mkw ON r.movie_id = mkw.movie_id
WHERE
    r.production_year > 1990
    AND (ar.total_cast IS NULL OR ar.total_cast > 0)
ORDER BY
    r.production_year DESC, r.movie_rank;

WITH excluded_movies AS (
    SELECT
        DISTINCT m.movie_id
    FROM 
        movie_info m
    WHERE
        m.note IS NULL 
        AND EXISTS (
            SELECT 1
            FROM movie_keyword mk
            WHERE mk.movie_id = m.movie_id
            HAVING COUNT(*) > 5
        )
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(em.movie_id, 'Excluded') AS excluded_status
FROM 
    aka_title t
LEFT JOIN 
    excluded_movies em ON t.id = em.movie_id
WHERE 
    t.title IS NOT NULL
ORDER BY 
    t.production_year DESC 
LIMIT 50;

WITH selected_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS row_num
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    r.title,
    r.production_year,
    sc.company_name,
    sc.company_type,
    sc.row_num
FROM 
    ranked_movies r
LEFT JOIN 
    selected_companies sc ON r.movie_id = sc.movie_id
WHERE 
    sc.row_num <= 3
ORDER BY 
    r.production_year DESC, r.title;

-- Additional corner case to check names with NULL logic
SELECT 
    n.name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count
FROM 
    name n
LEFT JOIN 
    cast_info ci ON n.id = ci.person_id
WHERE 
    n.gender IS NOT NULL
    AND (n.name IS NOT NULL OR n.name_pcode_nf IS NULL)
GROUP BY 
    n.id, n.name, n.gender
HAVING 
    COUNT(DISTINCT ci.movie_id) > 1 
ORDER BY 
    movie_count DESC;

-- Final bizarre case with complex conditions and NULL checks
SELECT 
    t.title,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT ci.id) AS role_count,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    (ci.note IS NULL OR ci.nr_order <= 5)
    AND t.production_year BETWEEN 1980 AND 2020
GROUP BY 
    t.title, a.name
HAVING 
    SUM(CASE WHEN ci
