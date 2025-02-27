WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        at.episode_of_id,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.level < 3 -- Limit depth to 3 for performance
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
)
SELECT
    fm.title,
    fm.production_year,
    fm.kind_id,
    COALESCE(fc.full_cast, 0) AS full_cast_count,
    fm.company_count
FROM
    FilteredMovies fm
LEFT JOIN (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS full_cast
    FROM
        cast_info ci
    JOIN
        aka_title at ON ci.movie_id = at.id
    WHERE
        at.production_year >= 2000
    GROUP BY
        ci.movie_id
) fc ON fm.movie_id = fc.movie_id
WHERE
    fm.company_count > 0
ORDER BY
    fm.production_year DESC,
    fm.title ASC
LIMIT 50;

In this SQL query:

1. **Recursive Common Table Expression (CTE)**: We create a recursive CTE `MovieHierarchy` to gather movies made after 2000 and their linked movies up to 3 levels deep.
   
2. **Filtered Movies CTE**: The `FilteredMovies` CTE aggregates movie information by counting distinct companies for each movie.

3. **Outer Joins**: We use LEFT JOIN to connect filtered movies to a subquery that calculates the full cast count of each movie based on `cast_info`.

4. **Aggregate Functions**: We employ COUNT to calculate the number of companies and the number of people in the full cast.

5. **COALESCE function**: This function is used to handle cases where there might not be any cast for certain movies, defaulting to zero.

6. **WHERE clause**: The final query filters out movies with zero companies associated, ensuring only those with production companies are displayed.

7. **ORDER BY and LIMIT**: The final result is ordered by production year (descending) and title (ascending) and limited to the top 50 results for performance benchmarking.
