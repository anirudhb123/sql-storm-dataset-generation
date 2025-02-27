
WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY LENGTH(at.title) DESC) AS title_length_rank,
        at.id AS movie_id
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
),
cast_details AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
complete_details AS (
    SELECT 
        rt.title,
        rt.production_year,
        cd.actor_name,
        cd.role_name,
        co.company_name,
        co.company_type
    FROM 
        ranked_titles rt
    JOIN 
        cast_details cd ON rt.movie_id = cd.movie_id
    JOIN 
        company_details co ON rt.movie_id = co.movie_id
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' (' || role_name || ')', ', ') AS actors,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies
FROM 
    complete_details
GROUP BY 
    title, production_year
ORDER BY 
    production_year DESC, LENGTH(title) DESC
LIMIT 100;
