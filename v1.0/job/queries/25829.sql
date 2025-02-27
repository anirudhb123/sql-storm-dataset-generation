WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.actors,
    mw.additional_info
FROM 
    MoviesWithInfo mw
WHERE 
    mw.cast_count > 5
ORDER BY 
    mw.production_year DESC, mw.cast_count DESC
LIMIT 10;
