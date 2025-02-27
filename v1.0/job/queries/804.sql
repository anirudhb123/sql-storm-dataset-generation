
WITH RankedMovies AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
