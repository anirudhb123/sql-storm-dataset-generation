WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT
        c.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.person_id, r.role
),
company_info AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    GROUP BY
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    (CASE
        WHEN tr.year_rank <= 5 THEN 'Top 5 of Year'
        ELSE 'Beyond Top 5'
    END) AS title_rank_group,
    (SELECT 
        GROUP_CONCAT(DISTINCT a.name) 
     FROM 
        aka_name a 
     JOIN 
        cast_info ci ON a.person_id = ci.person_id 
     WHERE 
        ci.movie_id = t.id
    ) AS actor_names,
    COALESCE(ci.company_count, 0) AS associated_company_count
FROM 
    ranked_titles tr
LEFT JOIN 
    title t ON t.id = tr.title_id
LEFT JOIN 
    company_info ci ON ci.movie_id = t.id
WHERE 
    (t.title IS NOT NULL AND LENGTH(t.title) > 0)
    OR t.production_year IN (SELECT DISTINCT production_year FROM aka_title WHERE production_year < 2000)
ORDER BY 
    t.production_year DESC,
    title_rank_group DESC
FETCH FIRST 50 ROWS ONLY;
