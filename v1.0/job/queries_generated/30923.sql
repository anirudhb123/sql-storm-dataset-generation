WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        aka_title ak ON ak.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword mw ON mw.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON k.id = mw.keyword_id
    LEFT JOIN 
        cast_info cc ON cc.movie_id = m.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_per_year
    FROM 
        FilteredMovies
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.aka_names, 
    rm.cast_count,
    COALESCE(NULLIF(rm.cast_count, 0), -1) AS adjusted_cast_count,
    CASE 
        WHEN rm.rank_per_year <= 10 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    RankedMovies rm
WHERE 
    rm.cast_count > 0 
    AND rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year, rm.cast_count DESC;

This SQL query includes several advanced constructs:
1. **Recursive CTE** (`MovieHierarchy`) to build a hierarchy of movies that includes episodes.
2. **STRING_AGG** to collect alternative names and keywords associated with the movies.
3. **LEFT JOINs** to ensure we retrieve all movie data, even if some relationships do not exist.
4. **RANK()** window function to assign ranks based on the number of cast members for each movie by year.
5. **COALESCE and NULLIF** to handle potential NULL values in the cast count.
6. **CASE** statement to define categories based on the rank of movies.
7. A conditional filter in the `WHERE` clause to include only movies released within a specific range and having cast members.

This construction allows for performance benchmarking against various join strategies and logic handling for a complex dataset.
