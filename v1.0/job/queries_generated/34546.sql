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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  -- Limit depth to avoid infinite recursion
)

SELECT 
    ak.name AS actor_name,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    COUNT(DISTINCT cc.movie_id) AS total_movies_featured,
    SUM(CASE WHEN cc.status_id = 1 THEN 1 ELSE 0 END) AS movies_completed,
    COUNT(DISTINCT c.id) AS unique_companies,
    MAX(m.production_year) AS latest_movie_year
FROM 
    cast_info cc
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    complete_cast c ON cc.movie_id = c.movie_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id 
WHERE 
    ak.name IS NOT NULL 
    AND mh.title IS NOT NULL 
    AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY 
    ak.name, mh.title, mh.production_year
ORDER BY 
    total_movies_featured DESC, actor_name
LIMIT 50;
