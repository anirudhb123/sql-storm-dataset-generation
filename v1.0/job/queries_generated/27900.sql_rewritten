WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.actors, 
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.actors
ORDER BY 
    tm.cast_count DESC;