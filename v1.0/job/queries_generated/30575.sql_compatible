
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title mt ON m.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.movie_id
    WHERE 
        mh.level < 3
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    MAX(mt.production_year) AS latest_production_year,
    COUNT(DISTINCT CASE WHEN m.info_type_id = 1 THEN m.info END) AS special_info_count,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_ranking
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_info m ON c.movie_id = m.movie_id
LEFT JOIN 
    aka_title mt ON c.movie_id = mt.id
WHERE 
    a.name IS NOT NULL 
    AND mh.production_year IS NOT NULL
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC,
    latest_production_year DESC;
