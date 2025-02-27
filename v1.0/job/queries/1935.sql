WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
), TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
), CastMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        TopMovies tm ON ci.movie_id = tm.title_id
    GROUP BY 
        ci.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS all_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cm.cast_count, 0) AS number_of_cast,
    COALESCE(mi.all_info, 'No Info') AS info_summary
FROM 
    TopMovies tm
LEFT JOIN 
    CastMovies cm ON tm.title_id = cm.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.title_id = mi.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
