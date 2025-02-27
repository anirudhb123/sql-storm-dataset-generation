WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies in the 21st century

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        sub.title,
        sub.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title sub ON ml.linked_movie_id = sub.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 2  -- Limit the depth of the recursion
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    CASE 
        WHEN mt.production_year IS NOT NULL THEN mt.production_year
        ELSE 'Unknown Year'
    END AS production_year,
    COUNT(DISTINCT mi.info) AS info_count,
    STRING_AGG(DISTINCT mi.info ORDER BY mi.info) AS info_list,
    AVG(COALESCE(CAST(c.nr_order AS FLOAT), 0)) AS average_order
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.movie_id, mt.title, mt.production_year
ORDER BY 
    average_order DESC
LIMIT 10;

This query accomplishes multiple objectives:
- It uses a recursive CTE to create a hierarchy of movies, linking them via `movie_link`.
- It retrieves actor names, movie titles, production years, and counts various types of movie-related information while ensuring NULL checks and logical conditions.
- It employs an outer join to include all movies, even if they have no associated cast or info.
- It aggregates movie information into a string list and computes an average of their order alongside filtering criteria to focus on newer movies (post-2000).
