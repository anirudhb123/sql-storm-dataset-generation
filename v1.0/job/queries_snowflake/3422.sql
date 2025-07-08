
WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
TopMovies AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 3
),
MovieKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.actor_name,
    LISTAGG(DISTINCT tm.movie_title, '; ') WITHIN GROUP (ORDER BY tm.movie_title) AS top_movies,
    LISTAGG(DISTINCT mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_title = mk.movie_title
GROUP BY 
    tm.actor_name
HAVING 
    COUNT(DISTINCT tm.movie_title) > 1
ORDER BY 
    tm.actor_name;
