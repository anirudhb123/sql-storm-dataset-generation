WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Filter for movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth) AS rn
    FROM 
        MovieHierarchy mh
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tk.keywords,
    ci.cast_count,
    ci.cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    DistinctKeywords tk ON tm.movie_id = tk.movie_id
LEFT JOIN 
    CastInfo ci ON tm.movie_id = ci.movie_id
WHERE 
    tm.rn <= 5 -- Limit to top 5 movies per year
ORDER BY 
    tm.production_year DESC, 
    tm.depth ASC;
