WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
), ActorCount AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
), MoviesWithKeywords AS (
    SELECT 
        m.movie_title,
        m.production_year,
        k.keyword
    FROM 
        ActorCount m
    JOIN 
        movie_keyword mk ON m.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    m.movie_title,
    m.production_year,
    m.actor_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ActorCount m
LEFT JOIN 
    MoviesWithKeywords k ON m.movie_title = k.movie_title AND m.production_year = k.production_year
GROUP BY 
    m.movie_title, m.production_year, m.actor_count
ORDER BY 
    m.production_year DESC, m.actor_count DESC;
