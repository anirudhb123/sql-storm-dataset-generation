WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.hierarchy_level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(CASE WHEN at.production_year = 2020 THEN at.title END) AS latest_2020_movie,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC;
