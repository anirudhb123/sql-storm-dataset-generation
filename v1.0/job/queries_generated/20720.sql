WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_link AS ml ON mt.id = ml.movie_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL 

    UNION ALL

    SELECT 
        h.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        h.depth + 1
    FROM 
        movie_hierarchy AS h
    JOIN 
        movie_link AS ml ON h.linked_movie_id = ml.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    WHERE 
        h.depth < 3 -- Limit depth to avoid too much recursion
)

SELECT 
    a.id AS aka_id,
    a.name,
    a.md5sum,
    th.title AS top_level_title,
    mh.depth,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT th.title, ', ') AS linked_titles,
    CASE 
        WHEN COUNT(DISTINCT i.info) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_additional_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy AS mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title AS th ON mh.movie_id = th.id
LEFT JOIN 
    movie_info AS i ON th.id = i.movie_id AND i.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
GROUP BY 
    a.id, a.name, a.md5sum, th.title, mh.depth
HAVING 
    COUNT(DISTINCT c.movie_id) > 1 
    AND (mh.depth IS NULL OR mh.depth = 1 OR mh.depth > 2)
ORDER BY 
    total_movies DESC,
    a.name ASC
LIMIT 50;

### Explanation of the Query:

- **Common Table Expressions (CTEs)**: The `movie_hierarchy` CTE recursively builds a hierarchy of movies linked through `movie_link`, limited to a maximum depth of 3 to prevent excessive recursion.
  
- **Outer Joins**: The main SELECT utilizes LEFT JOIN to include `movie_info`, ensuring that movies without genres still appear in the results.

- **Window Functions and Aggregation**: Physical aggregation is performed (`COUNT(DISTINCT ...)`) to measure the number of movies associated with each actor and to collect linked movie titles.

- **String Aggregation**: Using `STRING_AGG()` to concatenate titles of linked movies into a single string.

- **NULL Logic**: The `HAVING` clause filters groups based on the conditions of movie depth and ensures that only those with more than one movie are included.

- **Complicated Expressions**: It includes a CASE statement to check the existence of additional information related to a specific info type (like genre).

- **Predicates and Filtering**: The use of nested subqueries allows filtering titles by movie types, integrating another layer of logical conditions.

- **Sorting and Limiting**: Finally, the output is ordered by the count of movies in descending order and name in ascending order while limiting to the top 50 results.

This query incorporates various SQL features and accounts for complicated logic, corner cases, and a rich structure within the provided database schema.
