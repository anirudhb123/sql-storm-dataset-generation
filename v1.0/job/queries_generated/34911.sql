WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(cast_info.nr_order, 0) AS nr_order
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        title t ON ml.linked_movie_id = t.id
    LEFT JOIN 
        cast_info ON t.id = cast_info.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ci.nr_order, 0) AS nr_order
    FROM 
        title t
    JOIN 
        movie_link ml ON t.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    h.title AS original_movie,
    h.production_year AS original_year,
    MAX(h.nr_order) AS max_order,
    COUNT(DISTINCT ml.linked_movie_id) AS related_movies_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS related_movie_titles
FROM 
    movie_hierarchy h
LEFT JOIN 
    movie_link ml ON h.movie_id = ml.movie_id
LEFT JOIN 
    aka_title mt ON ml.linked_movie_id = mt.id
WHERE 
    h.production_year >= 2000
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    MAX(h.nr_order) > 0
ORDER BY 
    original_year DESC, max_order DESC
LIMIT 10

### Explanation
- **Recursive CTE (movie_hierarchy)**: It builds a hierarchy of movies, linking them based on the `movie_link` table, so that we gather all related movies for each original movie.
- **LEFT JOINs**: Used to include movies even if they don’t have linked movies or cast information, ensuring no data is lost.
- **COALESCE**: Handles potential NULLs in the `nr_order` field, defaulting to 0 for the main movie.
- **Aggregations**: 
  - `MAX(h.nr_order)`: Finds the maximum order of cast roles for the related movies.
  - `COUNT(DISTINCT ml.linked_movie_id)`: Counts how many unique related movies exist.
  - `STRING_AGG`: Gathers the titles of related movies into a single string.
- **Filtering and Grouping**: It filters for movies produced after 2000, groups by original movie attributes, and ensures that only movies with valid cast orders are selected.
- **Ordering**: Results are ordered by production year and maximum cast order to focus on the most relevant movies from recent years.
- **Limit Clause**: Restricts the output to 10 rows, making it manageable for analysis purposes.
