WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(actor_name, ', ') AS cast
    FROM 
        RankedMovies
    GROUP BY 
        movie_id, title, production_year
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    mk.keywords IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.title;
