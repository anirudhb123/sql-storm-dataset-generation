WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- assuming 1 is for 'movie'
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    string_agg(DISTINCT mk.keyword, ', ') AS keywords,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT m.id) AS num_movies,
    MAX(m.production_year) AS latest_movie_year,
    AVG(COALESCE(mi.info::integer, 0)) AS avg_info_type -- assuming info is numeric
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, info::text, info_type_id 
     FROM movie_info WHERE info_type_id IN (SELECT id FROM info_type WHERE info like 'Rating%')) mi ON m.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
GROUP BY 
    a.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT m.id) > 5 AND 
    AVG(COALESCE(mi.info::integer, 0)) > 70
ORDER BY 
    num_movies DESC, a.name;
