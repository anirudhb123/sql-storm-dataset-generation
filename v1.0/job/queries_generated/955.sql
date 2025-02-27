WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
MoviesWithCast AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        cast_info ci ON mwk.movie_id = ci.movie_id
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    COALESCE(mc.cast_count, 0) AS cast_count,
    CASE 
        WHEN mc.cast_count > 5 THEN 'Popular' 
        WHEN mc.cast_count BETWEEN 1 AND 5 THEN 'Moderate' 
        ELSE 'No Cast'
    END AS cast_category
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    MoviesWithCast mc ON mwk.movie_id = mc.movie_id
WHERE 
    mwk.production_year >= 2000
ORDER BY 
    mwk.production_year DESC, mwk.title;
