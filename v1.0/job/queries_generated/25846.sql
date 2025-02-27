WITH actor_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        a.id, a.name, t.title, t.production_year
), company_details AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
), complete_movie_info AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        a.actor_name,
        a.movie_year,
        cd.company_name,
        cd.company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.actor_name) AS actor_order
    FROM 
        actor_movies a
    JOIN 
        title t ON a.movie_title = t.title AND a.movie_year = t.production_year
    JOIN 
        company_details cd ON t.id = cd.movie_id
)
SELECT 
    movie_id,
    movie_title,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies
FROM 
    complete_movie_info
GROUP BY 
    movie_id, movie_title
ORDER BY 
    movie_title;
