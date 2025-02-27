WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.hierarchy_path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.id = ml.linked_movie_id
)
SELECT
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS number_of_movies,
    AVG(CASE WHEN mt.kind IS NOT NULL THEN mt.production_year END) AS avg_year_of_movies,
    STRING_AGG(DISTINCT mh.hierarchy_path, '; ') AS movie_hierarchy_paths
FROM
    aka_name a
JOIN
    cast_info ci ON ci.person_id = a.person_id
JOIN
    complete_cast cc ON cc.movie_id = ci.movie_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN
    aka_title mt ON mt.id = mc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.id = mc.movie_id
WHERE
    a.name IS NOT NULL
AND
    (mt.production_year IS NULL OR mt.production_year > 2000)
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY
    number_of_movies DESC, avg_year_of_movies ASC
LIMIT 10;
