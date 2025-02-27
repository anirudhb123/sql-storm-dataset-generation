WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        title_path || at.title
    FROM 
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(mt.info_type_id) FILTER (WHERE mt.info_type_id IS NOT NULL) AS avg_info_type_id,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS performance_rank
FROM 
    movie_hierarchy m
JOIN cast_info ci ON ci.movie_id = m.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN movie_info mt ON mt.movie_id = m.movie_id
WHERE 
    m.level <= 2
    AND a.name IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    actor_name, movie_title, m.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    avg_info_type_id DESC,
    actor_name ASC;

This SQL query does the following:

1. It constructs a recursive Common Table Expression (CTE) called `movie_hierarchy` to traverse a movie hierarchy and fetch linked movies.
2. It selects details from the `movie_hierarchy`, `cast_info`, `aka_name`, `movie_keyword`, and `movie_info` tables.
3. It uses `COALESCE` to handle any NULL values for actor names gracefully.
4. It calculates the total number of distinct keywords associated with each movie.
5. It computes the average `info_type_id` for each movie, filtering out NULL values.
6. It applies a partitioned window function (`ROW_NUMBER`) to rank actors based on their latest movie appearances.
7. The `WHERE` clause filters only the movies released after 2000 and limits the hierarchy depth.
8. The `HAVING` clause ensures that only actors with more than two distinct keywords for their movies are returned.
9. Finally, it orders the output by `avg_info_type_id` in descending order, followed by actor names in ascending order.
