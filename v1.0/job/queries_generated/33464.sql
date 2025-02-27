WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        mt.linked_movie_id,
        l.title,
        mh.level + 1
    FROM 
        movie_link mt
    JOIN 
        aka_title l ON mt.linked_movie_id = l.id
    JOIN 
        movie_hierarchy mh ON mt.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit to 5 levels of depth
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info IS NOT NULL THEN mi.info::numeric ELSE 0 END) AS avg_info_value,
    CASE 
        WHEN COUNT(DISTINCT mi.info) > 0 THEN 'Has Info'
        ELSE 'No Info'
    END AS info_status
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
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.level
HAVING 
    AVG(CASE WHEN mi.info IS NOT NULL THEN mi.info::numeric ELSE 0 END) > 0
ORDER BY 
    mh.level DESC, actor_count DESC;

This query achieves the following:
- It defines a recursive Common Table Expression (`CTE`) to generate a hierarchy of movies starting from those produced after the year 2000 and includes up to 5 levels of linked movies.
- It performs multiple `LEFT JOIN`s to combine information about the cast and any associated movie information.
- It calculates the count of distinct actors for each movie, aggregates actor names into a single string, and computes the average value from the `movie_info` table while handling potential `NULL`s.
- It includes a `CASE` statement to categorize each movie based on whether it has any information or not.
- Finally, it filters the results based on the average information value, ensuring only movies with useful data are included, and sorts the results by the level of the movie within the hierarchy and then by the number of actors.
