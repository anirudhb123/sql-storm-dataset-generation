WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(NULLIF(COUNT(DISTINCT ci.movie_id), 0), 0) AS movies_with_multiple_roles,
    RANK() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    rank, total_movies DESC;
