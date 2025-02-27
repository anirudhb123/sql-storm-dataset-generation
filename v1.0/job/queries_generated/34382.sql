WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link mv
    JOIN 
        aka_title m ON mv.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND m.production_year > 2000
    AND (mh.depth IS NULL OR mh.depth <= 3)
GROUP BY 
    ak.name, m.title
HAVING 
    COUNT(DISTINCT m.movie_id) > 1
ORDER BY 
    movie_count DESC, avg_depth ASC;
