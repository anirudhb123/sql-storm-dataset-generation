WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieGenres AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mg.genres, 'No genres') AS genres,
        COALESCE(mci.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id
    LEFT JOIN 
        movie_info mci ON rm.movie_id = mci.movie_id AND mci.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    dmi.movie_id,
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.genres,
    dmi.additional_info
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year >= 2000
ORDER BY 
    dmi.cast_count DESC, dmi.production_year DESC
LIMIT 10;