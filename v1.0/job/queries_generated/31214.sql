WITH RECURSIVE movie_network AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM title m
    WHERE m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mn.depth + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_network mn ON ml.movie_id = mn.movie_id
    WHERE mn.depth < 3
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
)

SELECT 
    mn.movie_title,
    GROUP_CONCAT(DISTINCT rc.actor_name) AS cast,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies,
    COALESCE(SUM(mi.info_type_id), 0) AS total_info_types
FROM movie_network mn
LEFT JOIN movie_link ml ON mn.movie_id = ml.movie_id
LEFT JOIN ranked_cast rc ON mn.movie_id = rc.movie_id
LEFT JOIN (SELECT movie_id, info_type_id FROM movie_info GROUP BY movie_id, info_type_id) mi ON mn.movie_id = mi.movie_id
GROUP BY mn.movie_title
HAVING COUNT(DISTINCT rc.actor_name) > 2 AND total_info_types IS NOT NULL
ORDER BY linked_movies DESC, mn.movie_title ASC;

This SQL query does the following:

1. Uses a recursive CTE (`movie_network`) to find movies produced after 2000 and their linked movies up to a depth of 3.
2. Creates another CTE (`ranked_cast`) that ranks actors for each movie based on their order.
3. Combines results to form a comprehensive view of all relevant movies, their casts, and their linkages, while calculating the number of distinct linked movies and summing up info types associated with each movie.
4. Applies a GROUP BY to obtain unique movie titles, aggregating the actors and applying conditions in the HAVING clause to filter movies with more than 2 distinct actors and ensure that `total_info_types` is not NULL.
5. Orders the final results first by the number of linked movies (descending) and then alphabetically by movie title (ascending).
