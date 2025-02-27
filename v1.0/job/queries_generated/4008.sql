WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
)

SELECT 
    ak.name AS actor_name,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS tagline,
    STRING_AGG(DISTINCT c.name, ', ') AS companies,
    AVG(NULLIF(CASE WHEN cc.status_id = 1 THEN cc.movie_id END, NULL)) AS avg_status_one_movies
FROM 
    aka_name ak 
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    RankedTitles title ON ci.movie_id = title.title_id
LEFT JOIN 
    movie_keyword mk ON title.title_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON title.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON title.title_id = cc.movie_id
LEFT JOIN 
    movie_info mi ON title.title_id = mi.movie_id 
WHERE 
    ak.name IS NOT NULL
    AND title.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, title.title, title.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    title.production_year DESC, ak.name;
