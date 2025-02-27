WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (
            SELECT 
                id 
            FROM 
                kind_type 
            WHERE 
                kind = 'movie'
        )
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.episode_of_id
),
CastInfo AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS genres
    FROM 
        movie_keyword mk 
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.movie_id
),
MoviesWithDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ca.cast_count, 0) AS total_cast,
        COALESCE(mg.genres, 'No Genre') AS genres
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfo ca ON mh.movie_id = ca.movie_id
    LEFT JOIN 
        MovieGenres mg ON mh.movie_id = mg.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    m.genres,
    COUNT(m.title) OVER(PARTITION BY m.production_year) AS movies_per_year,
    ROW_NUMBER() OVER(ORDER BY m.production_year DESC, m.total_cast DESC) AS rank
FROM 
    MoviesWithDetails m
WHERE 
    m.total_cast > 2
    AND m.production_year IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    m.total_cast DESC
LIMIT 100;

This query builds a comprehensive performance benchmark by employing a recursive Common Table Expression (CTE) to establish a hierarchy of movies, together with the aggregation of cast counts and string manipulation to group genres. The use of window functions allows for further analytical depth, identifying how many movies were released each year while ranking the results based on certain criteria for analysis. The query incorporates various SQL constructs, including outer joins, CTEs, correlated subqueries, and window functions to extract meaningful insights from the dataset.
