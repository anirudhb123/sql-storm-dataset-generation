WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.nr_order) AS cast,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id 
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvMovie'))
    GROUP BY 
        a.title, a.production_year
),

top_movies AS (
    SELECT 
        title,
        production_year,
        cast,
        keywords,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS rn
    FROM 
        movie_details
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast,
    tm.keywords,
    tm.company_count
FROM 
    top_movies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;

SELECT 
    a.name AS actor_name,
    a.id AS actor_id,
    COALESCE(c.role, 'Unknown Role') AS role,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
GROUP BY 
    a.name, a.id, c.role
HAVING 
    COUNT(DISTINCT mc.company_id) > 3
ORDER BY 
    total_companies DESC;

SELECT 
    * 
FROM 
    (SELECT 
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year) AS rn
     FROM 
        aka_title a
     WHERE 
        a.production_year IS NOT NULL) sub
WHERE 
    rn % 2 = 0;

SELECT 
    DISTINCT a.name,
    LENGTH(a.name) AS name_length,
    CASE 
        WHEN a.gender IS NULL THEN 'Not Specified' 
        ELSE a.gender 
    END AS gender_specified
FROM 
    name a
WHERE 
    a.name_pcode_nf IS NOT NULL 
    OR a.name_pcode_cf IS NOT NULL
AND 
    NOT EXISTS (SELECT 1 FROM person_info pi WHERE pi.person_id = a.imdb_id AND pi.info_type_id = 1)
ORDER BY 
    name_length DESC;

SELECT 
    t.title,
    COALESCE(i.info, 'No Info') AS movie_info,
    COUNT(DISTINCT c.company_id) AS company_count
FROM 
    title t
LEFT JOIN 
    movie_info i ON t.id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Running time')
LEFT JOIN 
    movie_companies c ON t.id = c.movie_id
WHERE 
    t.production_year >= 2010
GROUP BY 
    t.title, i.info
HAVING 
    COUNT(c.company_id) > 0
ORDER BY 
    company_count DESC;
