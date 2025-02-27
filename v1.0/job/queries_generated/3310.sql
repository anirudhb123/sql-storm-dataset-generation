WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 10
),
Actors AS (
    SELECT 
        a.name AS actor_name, 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_name a 
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, c.movie_id
),
MoviesWithActors AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(da.actor_count, 0) AS actor_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        Actors da ON tm.movie_id = da.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    CASE 
        WHEN m.actor_count > 5 THEN 'Ensemble Cast'
        WHEN m.actor_count > 0 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_category,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MoviesWithActors m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    m.title, m.production_year, m.actor_count
ORDER BY 
    m.production_year DESC, 
    m.actor_count DESC
LIMIT 50;
