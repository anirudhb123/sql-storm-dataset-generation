WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL 

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Information') AS info,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, mi.info
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mi.info,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mi.info, mh.level
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.info,
    tm.rank
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.movie_id;

This SQL query is designed for performance benchmarking and is illustrative of several key constructs:

1. **Recursive Common Table Expression (CTE)**: `MovieHierarchy` recursively constructs a hierarchy of movies based on links indicating sequels or related movies.
2. **Outer Joins**: The `LEFT JOIN` is used to gather movie information and company counts even if there are no related records, ensuring that all movies in the hierarchy are included.
3. **Aggregations**: The `COUNT(DISTINCT mc.company_id)` counts unique companies associated with each movie.
4. **Window Functions**: `ROW_NUMBER()` is used to rank movies based on the number of companies associated with them within their hierarchy level.
5. **Complex Predicates**: The query effectively uses `COALESCE` to manage potential NULL values in the `info` field.
6. **Final Filtering and Sorting**: The main query selects top-ranked movies for each level of the hierarchy and orders them by their movie IDs for consistency in the output.
