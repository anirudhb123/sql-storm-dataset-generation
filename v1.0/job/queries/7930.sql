WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        aka_title a ON a.movie_id = t.id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS infos
    FROM 
        movie_info mi 
    JOIN 
        HighCastMovies m ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    h.title,
    h.production_year,
    h.cast_count,
    COALESCE(mi.infos, 'No info available') AS additional_info
FROM 
    HighCastMovies h
LEFT JOIN 
    MovieInfo mi ON h.movie_id = mi.movie_id
ORDER BY 
    h.production_year DESC, 
    h.cast_count DESC;
