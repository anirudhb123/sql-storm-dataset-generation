WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id = (SELECT id FROM title WHERE title = 'Inception' LIMIT 1)

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.person_id
)

SELECT 
    t.title,
    t.production_year,
   GROUP_CONCAT(DISTINCT ak.name) AS actors,
    COUNT(DISTINCT mc.company_id) AS num_production_companies,
    AVG(mo.info) AS avg_movie_rating,
    SUM(CASE WHEN a.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN a.gender = 'M' THEN 1 ELSE 0 END) AS male_count
FROM 
    title t
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_info mo ON t.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    name a ON ak.person_id = a.imdb_id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
GROUP BY 
    t.title,
    t.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 5
ORDER BY 
    avg_movie_rating DESC NULLS LAST
OFFSET 0 LIMIT 50;
