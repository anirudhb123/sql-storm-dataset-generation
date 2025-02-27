WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(tm.cast_names::text, ', ') AS all_cast_names,
    COUNT(DISTINCT mk.id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC;
