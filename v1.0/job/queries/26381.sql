
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(ci.movie_id) AS movies_appeared
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    WHERE 
        p.name IS NOT NULL
    GROUP BY 
        p.id, p.name
),
castings AS (
    SELECT 
        movie.movie_id,
        movie.title,
        movie.production_year,
        actor.name AS actor_name,
        actor.movies_appeared,
        movie.keywords,
        movie.companies
    FROM 
        movie_details movie
    JOIN 
        cast_info ci ON movie.movie_id = ci.movie_id
    JOIN 
        actor_details actor ON ci.person_id = actor.person_id
)

SELECT 
    c.title,
    c.production_year,
    c.actor_name,
    c.movies_appeared,
    c.keywords,
    c.companies
FROM 
    castings c
WHERE 
    c.movies_appeared > 5
ORDER BY 
    c.production_year DESC, c.title;
