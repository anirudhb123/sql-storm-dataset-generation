WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT mh.title) AS movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(mh.production_year) AS last_movie_year
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id 
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    last_movie_year DESC
LIMIT 10;
