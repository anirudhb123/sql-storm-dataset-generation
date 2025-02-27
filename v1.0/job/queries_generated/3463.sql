WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        mt.title, mt.production_year
),

MoviesWithKeywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        mk.keyword
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
),

HighCastMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)

SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS keyword
FROM 
    HighCastMovies hcm
LEFT JOIN 
    MoviesWithKeywords mk ON hcm.title = mk.title AND hcm.production_year = mk.production_year
ORDER BY 
    hcm.production_year DESC, 
    hcm.cast_count DESC;
