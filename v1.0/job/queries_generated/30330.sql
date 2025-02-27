WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Base Case: Only movies from the year 2000 onwards
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(gc.name, 'Unknown') AS company_name,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    AVG(CASE WHEN ni.info IS NOT NULL THEN ni.info::numeric ELSE NULL END) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name gc ON mc.company_id = gc.id
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info ni ON m.movie_id = ni.movie_id AND ni.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
GROUP BY 
    m.title, m.production_year, gc.name
HAVING 
    COUNT(DISTINCT c.person_id) > 5 -- Only movies with more than 5 cast members
ORDER BY 
    m.production_year DESC, rank;

