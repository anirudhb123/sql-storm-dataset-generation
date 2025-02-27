WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 

DirectorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM 
        cast_info ci
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        ci.movie_id
),

MovieGenres AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(dc.director_count, 0) AS director_count,
    COALESCE(mg.genres, 'No genres available') AS genres
FROM 
    MovieHierarchy mh
LEFT JOIN 
    DirectorCounts dc ON mh.movie_id = dc.movie_id
LEFT JOIN 
    MovieGenres mg ON mh.movie_id = mg.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.level, mh.title;

This SQL query performs the following operations:

1. **Recursive CTE (MovieHierarchy)**: Recursively collects movies linked to other movies from the `movie_link` table, starting from movies produced after 2000.

2. **DirectorCounts CTE**: Aggregates the number of distinct directors associated with each movie by filtering based on role types.

3. **MovieGenres CTE**: Collects genre keywords associated with movies produced after 2000.

4. **Main SELECT**: Combines the results from the recursive CTE and the other two CTEs using LEFT JOINs. It selects the movie title, its level in the hierarchy, the count of directors, and the associated genres, applying COALESCE to handle NULLs effectively.

5. **Ordering**: The results are ordered by the hierarchy level and movie titles. 

This query effectively demonstrates a variety of SQL techniques including CTEs, left joins, aggregations, and string handling, making it suitable for a performance benchmarking scenario.
