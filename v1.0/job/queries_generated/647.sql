WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count,
        MAX(m.note) AS movie_note
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast co ON a.id = co.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL 
        AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        year_rank,
        cast_count,
        movie_note
    FROM 
        RankedMovies
    WHERE 
        (cast_count > 5 OR movie_note IS NOT NULL)
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        year_rank,
        cast_count,
        movie_note
    FROM 
        FilteredMovies
    WHERE 
        year_rank <= 3
)
SELECT 
    title,
    production_year,
    cast_count,
    COALESCE(movie_note, 'No notes available') AS movie_note
FROM 
    TopMovies
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10;

