WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(tm.cast_names, ', ') AS full_cast
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
