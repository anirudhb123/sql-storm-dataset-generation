WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt.episode_of_id, mt.id) AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        sub.title,
        sub.production_year,
        sub.episode_of_id,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title sub ON ml.linked_movie_id = sub.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM m.production_year) ORDER BY m.production_year DESC) AS year_rank
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
GROUP BY 
    m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.id) > 5 AND 
    SUM(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office') THEN 1 ELSE 0 END) = 0
ORDER BY 
    m.production_year DESC, cast_count DESC;
