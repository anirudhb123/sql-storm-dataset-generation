WITH RECURSIVE movie_hierarchy AS (
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
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 3 -- Limit recursion depth
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT CAST_INFO.movie_id) AS total_movies,
    AVG(CASE WHEN mc.status_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_have_complete_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    mh.level AS movie_level,
    MIN(mh.production_year) AS first_movie_year,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast mc ON mc.movie_id = mh.movie_id AND mc.subject_id = a.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, mh.level
ORDER BY 
    total_movies DESC, first_movie_year ASC;

This SQL query performs the following:

1. **Recursive CTE (Common Table Expression)** to create a hierarchy of movies linked together by their relationships, allowing for up to 3 levels deep. Each level corresponds to a linked movie.

2. **Joins** variously on `aka_name`, `cast_info`, the recursively built `movie_hierarchy`, `movie_keyword`, and `keyword` tables.

3. Calculates:
   - Total number of movies for each actor.
   - Average of movies that have a complete cast associated with each actor.
   - Aggregates keywords related to the movies featuring the actor.
   - Retrieves the production year of the first and latest movie across the hierarchical links.

4. **Group by** actor name and the movie level to compile statistics at each level of the movie hierarchy.

5. **Orders** results first by the total number of movies, then by the earliest production year, providing impressive and informative metrics about actors and their film contributions. 

This query is designed for performance benchmarking through complex operations and should be tested against real datasets to evaluate efficiency and output accuracy in various scenarios.
