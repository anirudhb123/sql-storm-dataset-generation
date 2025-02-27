WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        ARRAY[m.title] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.path || mt.title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mk ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mt.id = mk.linked_movie_id
    WHERE 
        mh.level < 3 -- limiting depth of hierarchy
)

SELECT 
    coalesce(ca.name, cn.name) AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, ', ') AS related_movies,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS percentage_with_info,
    RANK() OVER (PARTITION BY ca.name ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS movie_rank
FROM 
    cast_info cc
JOIN 
    aka_name ca ON ca.person_id = cc.person_id
LEFT JOIN 
    complete_cast cco ON cco.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = cc.movie_id
LEFT JOIN 
    company_name cn ON cn.id = (
        SELECT 
            mc.company_id 
        FROM 
            movie_companies mc 
        WHERE 
            mc.movie_id = cc.movie_id 
        LIMIT 1
    )
WHERE 
    ca.name IS NOT NULL 
    AND (EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = cc.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')))
GROUP BY 
    ca.name, cn.name
HAVING 
    COUNT(DISTINCT cc.movie_id) > 1
ORDER BY 
    total_movies DESC, actor_name;

This SQL query includes various constructs:

- **Recursive CTE** to build a hierarchy of movies related by links up to 3 levels deep.
- **Outer joins** to include actors even if their associated movies do not have corresponding company names or complete casts.
- **Coalescing** actor and company names to ensure one value is preferred when the other could be null.
- **Window functions** for ranking actors based on the number of movies they are in.
- **Subqueries** to handle specific conditions such as obtaining information from related tables efficiently.
- **Group by** with a condition in the HAVING clause to filter actors who have been in more than one movie.
- **Aggregate functions** like COUNT, STRING_AGG, and AVG to provide insightful statistics about actors and the movies they are associated with.

