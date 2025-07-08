
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mh.movie_id = mt.episode_of_id
)

SELECT 
    a.name AS actor_name,
    s.title AS series_title,
    COUNT(s.movie_id) AS episode_count,
    MAX(s.production_year) AS latest_production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COALESCE(ac.name, 'Unknown') AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy s ON s.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = s.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = s.movie_id
LEFT JOIN 
    company_name ac ON ac.id = mc.company_id AND ac.country_code IS NOT NULL
WHERE 
    s.level = 1 AND s.production_year >= 2000
GROUP BY 
    a.name, s.title, ac.name
HAVING 
    COUNT(s.movie_id) > 3
ORDER BY 
    latest_production_year DESC, actor_name;
