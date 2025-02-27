WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000             -- Starting point for year 2000 and onwards
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    COALESCE(NULLIF(m.title, ''), 'Unknown Title') AS movie_title,
    mh.production_year,
    COUNT(mh.movie_id) OVER (PARTITION BY ak.person_id) AS total_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(CASE WHEN mt.kind_id = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY ak.person_id) AS avg_feature_length_movies,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    aka_title m ON mh.movie_id = m.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.person_id, m.title, mh.production_year
HAVING 
    COUNT(mh.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name
FETCH FIRST 10 ROWS ONLY;

### Breakdown of the SQL Query:

1. **Recursive CTE (MovieHierarchy)**: 
   - Starts with movies from the year 2000 onwards and recursively finds linked movies.

2. **Main SELECT**:
   - Joins `aka_name`, `cast_info`, `MovieHierarchy`, `movie_keyword`, and `keyword`.
   - Uses `COALESCE` and `NULLIF` to handle potential NULL values in `title`.
   - Calculates the total number of movies acted in (`total_movies`) using a window function.
   - Computes the average feature-length movies for each actor.
   - Assigns a row number (`rn`) to rank movies by production year.

3. **Filters and Grouping**:
   - Filters out actors without a name, ensuring only relevant data is aggregated.
   - Groups by actor and movie details and ensures only actors with more than 5 movies are returned.

4. **Ordering and Limiting**:
   - Results are ordered by the total number of movies and actor names, retrieving only the top 10 results.

This query is designed to benchmark various SQL functionalities including recursive queries, window functions, joins, and GROUP BY logic.
