WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.parent_id, 0) AS parent_id,
        1 AS depth
    FROM
        title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.parent_id, 0) AS parent_id,
        depth + 1 AS depth
    FROM
        title m
    JOIN
        movie_hierarchy mh ON m.parent_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(mh.depth) AS average_depth
FROM
    aka_name ak
JOIN
    cast_info c ON ak.person_id = c.person_id
JOIN
    aka_title at ON c.movie_id = at.movie_id
JOIN
    movie_keyword mk ON at.movie_id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    title t ON at.movie_id = t.id
LEFT JOIN
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY
    ak.name, t.title, t.production_year
HAVING
    COUNT(DISTINCT c.id) > 5
ORDER BY
    average_depth DESC, total_cast DESC;

### Explanation:
1. **Recursive CTE (Common Table Expression)**: The `movie_hierarchy` CTE builds a hierarchy of movies with their depths in the hierarchy (assuming a parent-child relationship with movies). It filters for movies produced after 2000.
  
2. **Main Query**: 
   - Joins `aka_name`, `cast_info`, `aka_title`, `movie_keyword`, `keyword`, and `title` tables.
   - Filters out null or empty actor names and movies produced between 2000 and 2023.
   - Uses `STRING_AGG` to concatenate distinct keywords associated with each movie.
   - Counts the number of distinct cast members associated with each actor and movie.
   - Calculates the average depth of the movies from the hierarchy CTE.
  
3. **Group and Having Clause**: Groups the results by actor and movie information, showing only those with more than 5 cast members.

4. **Ordering**: Results are ordered first by average depth (descending) and then by the total number of cast members (also descending). 

This approach allows benchmarking the performance of complex SQL interactions while utilizing various SQL constructs, including recursive queries, aggregate functions, and filtering logic.
