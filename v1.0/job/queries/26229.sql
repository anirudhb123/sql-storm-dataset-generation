WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors_list 
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        mi.info AS additional_info
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.id = mi.id
    WHERE 
        mi.note ILIKE '%important%'
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.actors_list,
    mi.additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 20;
