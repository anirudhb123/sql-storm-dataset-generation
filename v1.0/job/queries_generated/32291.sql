WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Focus on movies from the year 2000 onwards

    UNION ALL

    SELECT
        ml.linked_movie_id,
        sub.movie_title || ' (linked to: ' || mt.title || ')' AS movie_title,
        sub.production_year,
        sub.level + 1
    FROM
        movie_link ml
    JOIN 
        MovieHierarchy sub ON ml.movie_id = sub.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    m.movie_title,
    m.production_year,
    ARRAY_AGG(DISTINCT c.name) AS cast_names,
    COUNT(DISTINCT kc.keyword) FILTER (WHERE kc.keyword IS NOT NULL) AS keyword_count,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS avg_person_info_length,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS movie_rank
FROM
    MovieHierarchy m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN
    person_info pi ON c.person_id = pi.person_id
WHERE
    m.level <= 2  -- Limit to two levels of movie links
GROUP BY
    m.movie_id, m.movie_title, m.production_year
ORDER BY
    m.production_year DESC, keyword_count DESC;

### Explanation:
1. **Recursive CTE (Common Table Expression):** The query starts with a CTE named `MovieHierarchy` that builds a hierarchy of movies linked to each other. It focuses on films produced since 2000.

2. **Outer Joins:** Various outer joins are used to gather data from the cast, keywords, and person info tables even if there may not be corresponding entries, which means movies without keywords or casts will still appear.

3. **Aggregations and Filtering:**
   - An array of unique cast names is created using `ARRAY_AGG`.
   - The keyword count uses the `FILTER` clause to count keywords only if they're not NULL.
   - It also calculates the average length of information associated with each person, using a coalescing method for NULL handling.

4. **Window Function:** `ROW_NUMBER()` is utilized for ranking the movies based on the count of distinct casts.

5. **Ordering and Grouping:** The final result is grouped by movie details and ordered by production year and keyword count for easier analysis.

This query demonstrates the use of multiple SQL constructs while providing insights into a movie's details along with associated cast and keywords.
