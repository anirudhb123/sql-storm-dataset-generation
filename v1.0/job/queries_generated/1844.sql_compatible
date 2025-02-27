
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year >= 2000
),
TopCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(ka.name, ', ') AS cast_names,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        tc.cast_names,
        tc.total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopCast tc ON rm.movie_id = tc.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    fm.title,
    COALESCE(fm.production_year::VARCHAR, 'Unknown Year') AS production_year,
    COALESCE(fm.cast_names, 'No Cast Available') AS cast_names,
    CASE 
        WHEN fm.total_cast IS NOT NULL AND fm.total_cast > 0 THEN 'Active Cast'
        ELSE 'No Active Cast'
    END AS cast_status
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.title;
