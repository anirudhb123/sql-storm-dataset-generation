WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 1990
    GROUP BY 
        t.id
), 
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS ranking
    FROM 
        MovieDetails
    WHERE 
        cast_count > 0
), 
MoviesWithNotes AS (
    SELECT 
        m.title,
        COALESCE(mi.info, 'No Info') AS movie_note,
        m.production_year,
        m.cast_count
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
)

SELECT 
    movie_title,
    production_year,
    cast_count,
    movie_note
FROM 
    MoviesWithNotes
WHERE 
    ranking <= 10
ORDER BY 
    production_year DESC,
    cast_count DESC;
