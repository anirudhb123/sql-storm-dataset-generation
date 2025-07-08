
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS actor_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
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
        t.production_year >= 2000 
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
        rank <= 5 
)
SELECT 
    production_year,
    LISTAGG(DISTINCT movie_title, '; ') WITHIN GROUP (ORDER BY movie_title) AS movies,
    LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
    SUM(actor_count) AS total_actors,
    LISTAGG(DISTINCT keywords, ', ') WITHIN GROUP (ORDER BY keywords) AS all_keywords
FROM 
    TopMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
