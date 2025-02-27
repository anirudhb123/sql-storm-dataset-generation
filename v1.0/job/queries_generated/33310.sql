WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title AS movie_title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mt.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT ak.title, ', ') AS linked_movie_titles,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
AND 
    (mt.production_year >= 2000 OR mt.production_year IS NULL)
GROUP BY 
    a.id 
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    total_movies DESC
LIMIT 10;
