WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
CastStats AS (
    SELECT
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_details
    FROM
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.*,
        cs.cast_count,
        cs.cast_details
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastStats cs ON rm.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS cast_count,
    md.cast_details,
    CASE 
        WHEN md.cast_count IS NULL OR md.cast_count = 0 THEN 'No Cast Available'
        ELSE md.cast_details
    END AS cast_info,
    CASE 
        WHEN md.total_movies > 10 THEN 'Popular Year'
        ELSE 'Less Popular Year'
    END AS movie_trend
FROM 
    MovieDetails md
WHERE 
    md.rn <= 5
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
