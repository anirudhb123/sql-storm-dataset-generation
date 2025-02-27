WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id
),
PersonDetails AS (
    SELECT 
        pa.person_id,
        p.name AS person_name,
        COALESCE(pa.note, 'No Role') AS role_note
    FROM 
        cast_info pa
    JOIN 
        aka_name p ON pa.person_id = p.person_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    pd.person_name,
    pd.role_note,
    mi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    PersonDetails pd ON rm.movie_id = pd.person_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank = 1
    AND (rm.production_year IS NOT NULL OR pd.role_note IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.movie_title ASC
LIMIT 100;
