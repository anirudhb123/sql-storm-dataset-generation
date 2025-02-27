WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id 
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    ARRAY_AGG(DISTINCT a.name) AS Actors,
    COUNT(DISTINCT m2.movie_id) AS Num_Linked_Movies,
    AVG(CASE 
            WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS Actor_Role_Avg
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_link ml ON m.movie_id = ml.movie_id
LEFT JOIN 
    aka_title m2 ON ml.linked_movie_id = m2.id
WHERE 
    m.production_year IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT a.person_id) >= 3
ORDER BY 
    m.production_year DESC, m.title;
