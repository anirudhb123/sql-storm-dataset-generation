WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 -- filter for movies post-2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name, 
        actor_count, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5 -- limit to top 5 actors per movie
)
SELECT 
    production_year,
    STRING_AGG(DISTINCT movie_title, '; ') AS movies,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    SUM(actor_count) AS total_actors,
    STRING_AGG(DISTINCT keywords) AS all_keywords
FROM 
    TopMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
