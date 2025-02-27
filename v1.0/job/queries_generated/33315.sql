WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        a.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE 
        WHEN mt.production_year IS NOT NULL THEN (EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year) 
        ELSE NULL 
    END) AS avg_years_since_release,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    COUNT(DISTINCT k.keyword) AS total_keywords
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mh.level IS NOT NULL
GROUP BY 
    ak.name
ORDER BY 
    total_movies DESC
LIMIT 10;
