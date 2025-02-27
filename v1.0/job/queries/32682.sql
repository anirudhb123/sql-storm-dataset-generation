WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mh.level + 1 AS level,
        mt.production_year
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT m.movie_id) AS num_movies,
    MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year END) AS max_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(DISTINCT m.movie_id) DESC) AS rank
FROM 
    aka_name p
LEFT JOIN 
    cast_info ci ON p.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_title mt ON m.movie_id = mt.id
WHERE 
    p.name IS NOT NULL
    AND (mt.production_year >= 2000 OR mt.production_year IS NULL)
GROUP BY 
    p.name, p.id
HAVING 
    COUNT(DISTINCT m.movie_id) > 1
ORDER BY 
    num_movies DESC, rank ASC;
