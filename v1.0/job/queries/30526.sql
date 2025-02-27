
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.depth) AS average_depth,
    ARRAY_AGG(DISTINCT kw.keyword) AS associated_keywords,
    CASE 
        WHEN AVG(mh.depth) IS NULL THEN 'No Data' 
        ELSE 'Data Available' 
    END AS data_availability
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    company_name cn ON ci.movie_id = cn.imdb_id
WHERE 
    a.name IS NOT NULL
    AND cn.country_code IS NOT NULL
    AND mh.production_year >= 2000
GROUP BY 
    a.name, a.person_id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC, 
    average_depth ASC;
