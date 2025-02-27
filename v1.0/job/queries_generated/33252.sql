WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        lm.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title at ON lm.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.title) AS rank
    FROM 
        MovieHierarchy mh
),

InfoAggregation AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS all_info
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    WHERE 
        mi.note IS NULL
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.level,
    rm.rank,
    COALESCE(ia.all_info, 'No Info Available') AS movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    InfoAggregation ia ON rm.movie_id = ia.movie_id
WHERE 
    rm.level <= 3
ORDER BY 
    rm.level, rm.rank;

-- Additional metrics for benchmarking
EXPLAIN ANALYZE
SELECT 
    COUNT(DISTINCT rm.movie_id) AS total_movies,
    COUNT(DISTINCT ia.movie_info) AS total_info_entries
FROM 
    RankedMovies rm
LEFT JOIN 
    InfoAggregation ia ON rm.movie_id = ia.movie_id
WHERE 
    ia.all_info IS NOT NULL;

This SQL query consists of several constructs:

- **Common Table Expressions (CTEs)**: 
  - The `MovieHierarchy` CTE recursively retrieves movies and their linked movies with a level indication.
  - The `RankedMovies` CTE ranks movies within each hierarchical level using window functions.
  - The `InfoAggregation` CTE aggregates movie information into a concatenated string based on distinct entries.

- **Outer Join**: The final selection uses a LEFT JOIN to include movies even when they have no associated info.

- **String Aggregation**: `STRING_AGG` concatenates distinct info entries into a single string.

- **NULL Logic**: The `COALESCE` function handles cases where no information is available.

- **Correlation for Benchmarking**: The `EXPLAIN ANALYZE` statement at the end provides performance metrics for the executed query.

This allows for a scalable performance benchmarking exercise, showcasing the impact of complex joins, subqueries, and aggregations.
