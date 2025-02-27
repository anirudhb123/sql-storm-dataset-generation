
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year BETWEEN 2000 AND 2020
),
TopCast AS (
    SELECT 
        ci.movie_id, 
        COUNT(*) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithKeyword AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    tc.cast_count, 
    mwk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopCast tc ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = tc.movie_id LIMIT 1)
LEFT JOIN 
    MoviesWithKeyword mwk ON rm.title = (SELECT mt.title FROM aka_title mt WHERE mt.id = mwk.movie_id LIMIT 1)
WHERE 
    tc.cast_count > 5
ORDER BY 
    rm.production_year DESC, 
    tc.cast_count DESC;
