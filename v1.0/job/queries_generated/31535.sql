WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m2.title, '') AS linked_title,
        0 AS depth
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN title m2 ON ml.linked_movie_id = m2.id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m2.title, '') AS linked_title,
        mh.depth + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title m ON ml.linked_movie_id = m.id 
    LEFT JOIN movie_link ml2 ON m.id = ml2.movie_id
    LEFT JOIN title m2 ON ml2.linked_movie_id = m2.id
    WHERE mh.depth < 3  -- Limits the depth of the hierarchy
)

SELECT
    p.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    STRING_AGG(DISTINCT m.title, ', ') AS movies,
    AVG(m.production_year) AS average_year,
    MAX(mh.depth) AS max_depth_of_links,
    CASE 
        WHEN COUNT(DISTINCT ci.movie_id) > 5 THEN 'Prolific Actor'
        WHEN COUNT(DISTINCT ci.movie_id) > 0 THEN 'Occasional Actor'
        ELSE 'No Movies'
    END AS actor_category
FROM aka_name p
JOIN cast_info ci ON p.person_id = ci.person_id
JOIN title m ON ci.movie_id = m.id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = m.id
WHERE p.name IS NOT NULL
GROUP BY p.name
HAVING AVG(m.production_year) > 2000 AND COUNT(DISTINCT ci.movie_id) > 0
ORDER BY movie_count DESC, average_year ASC;


This elaborate SQL query performs the following tasks:

1. **Recursive CTE (`movie_hierarchy`)**: It builds a hierarchy of movies starting from those produced from 2000 onwards and gathers linked movie titles. It limits the recursion to a maximum depth of 3.

2. **Main Query**: It retrieves actor names alongside various metrics, such as the count of distinct movies they participated in, aggregation of movie titles, average production year, maximum depth of movie links, and a categorization of the actors based on their prolificacy.

3. **Filtering and Grouping**: The query filters actors who have appeared in movies post-2000 and groups the results by actor names. It includes various predicates and string expressions (e.g., `STRING_AGG` for concatenating movie titles) to present meaningful insights about actors.

4. **Handling NULL Logic**: The use of `COALESCE` in the CTE ensures that even if there are no linked movies, it still returns an empty string rather than NULL.

5. **Ordering**: Finally, the results are ordered first by the count of movies (in descending order) and then by the average production year (in ascending order).
