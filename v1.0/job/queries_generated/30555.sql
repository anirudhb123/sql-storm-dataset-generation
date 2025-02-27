WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year = 2022

    UNION ALL

    SELECT m.id AS movie_id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3 -- limiting depth to avoid overly large results
)

SELECT
    n.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) * 100 AS percentage_before_2000,
    ARRAY_AGG(DISTINCT a.title ORDER BY a.title) AS movie_titles,
    FIRST_VALUE(a.title) OVER (PARTITION BY n.id ORDER BY a.production_year DESC) AS latest_movie_title,
    EXTRACT(YEAR FROM NOW()) - MAX(m.production_year) AS years_since_last_release
FROM
    aka_name n
LEFT JOIN
    cast_info c ON n.person_id = c.person_id
LEFT JOIN
    aka_title a ON c.movie_id = a.id
LEFT JOIN
    movie_info mi ON a.id = mi.movie_id
LEFT JOIN
    movie_hierarchy mh ON a.id = mh.movie_id
WHERE
    n.name IS NOT NULL
    AND (mi.info IS NULL OR mi.info NOT LIKE '%unreleased%')
GROUP BY
    n.name
HAVING
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY
    movies_count DESC,
    years_since_last_release
LIMIT 10;

### Explanation:
1. **Recursive Common Table Expression (CTE)**: The `movie_hierarchy` CTE fetches movies released in 2022 and their linked movies up to 3 levels of depth.
   
2. **Main SELECT**: It retrieves actor names, counts the associated movies, calculates the percentage of movies before the year 2000, lists movie titles, finds the latest movie title, and computes years since the last release.
   
3. **JOINs**: The `LEFT JOIN` operations connect various tables, allowing for an inclusive retrieval even if some entries might not be present.

4. **HAVING Clause**: Ensures that only actors with more than 5 movies are considered in the final output.

5. **Window Function**: `FIRST_VALUE` gets the title of the latest movie for each actor using window partitioning.

6. **Array Aggregation**: Collects all titles for each actor into an array.

7. **Complex Predicate Logic**: Ensures the response is curated based on specific conditions, including the checks for NULL values and excluding unreleased movies.

8. **Ordering and Limiting the Results**: The final output is sorted based on the counts of movies and years since the last release, with a limit of 10 results.
