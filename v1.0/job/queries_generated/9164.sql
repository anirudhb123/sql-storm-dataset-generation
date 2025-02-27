WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
),
company_movies AS (
    SELECT 
        c.name AS company_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        title t ON mc.movie_id = t.id
),
full_details AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        am.actor_name,
        cm.company_name
    FROM 
        ranked_titles r
    LEFT JOIN 
        actor_movies am ON r.title = am.movie_title AND r.production_year = am.production_year
    LEFT JOIN 
        company_movies cm ON r.title = cm.movie_title AND r.production_year = cm.production_year
)
SELECT 
    title,
    production_year,
    ARRAY_AGG(DISTINCT actor_name) AS actors,
    ARRAY_AGG(DISTINCT company_name) AS companies
FROM 
    full_details
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
