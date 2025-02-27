WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
keyword_movies AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
detailed_info AS (
    SELECT 
        ma.actor_id,
        ma.actor_name,
        ma.movie_id,
        ma.movie_title,
        ma.production_year,
        km.keyword,
        cm.company_name,
        cm.company_type
    FROM 
        movie_actors ma
    LEFT JOIN 
        keyword_movies km ON ma.movie_id = km.movie_id
    LEFT JOIN 
        company_movies cm ON ma.movie_id = cm.movie_id
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(company_name, ' (', company_type, ')'), '; ') AS companies
FROM 
    detailed_info
GROUP BY 
    actor_name, movie_title, production_year
ORDER BY 
    actor_name, production_year DESC;
