WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info c ON tm.movie_id = c.movie_id 
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    COALESCE(mi.info, 'No trivia available') AS trivia
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'trivia')
WHERE 
    md.cast_count > 0 
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
