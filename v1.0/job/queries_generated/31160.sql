WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title
),

TopMovies AS (
    SELECT 
        f.movie_id,
        f.movie_title,
        f.cast_count,
        f.keyword_count,
        ROW_NUMBER() OVER (ORDER BY f.cast_count DESC, f.keyword_count DESC) AS rn
    FROM 
        FilteredMovies f
    WHERE 
        f.cast_count > 5
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.cast_count,
    tm.keyword_count,
    CASE 
        WHEN tm.cast_count > 10 THEN 'High Cast'
        WHEN tm.cast_count BETWEEN 6 AND 10 THEN 'Medium Cast'
        ELSE 'Low Cast'
    END AS cast_category,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.movie_id AND cc.status_id IS NOT NULL) AS complete_cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.cast_count DESC, tm.keyword_count DESC;

-- Performance Benchmarking
EXPLAIN ANALYZE 
SELECT 
    COUNT (*) 
FROM 
    TopMovies;
