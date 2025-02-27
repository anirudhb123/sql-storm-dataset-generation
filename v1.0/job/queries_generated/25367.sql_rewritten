WITH recent_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword 
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2020
),
cast_details AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order < 4  
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
complete_info AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        CASTD.actor_name,
        COMP.company_name,
        COMP.company_type,
        r.keyword
    FROM 
        recent_movies r
    LEFT JOIN 
        cast_details CASTD ON r.movie_id = CASTD.movie_id
    LEFT JOIN 
        company_details COMP ON r.movie_id = COMP.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    STRING_AGG(DISTINCT actor_name, ', ') AS actors, 
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM 
    complete_info
GROUP BY 
    movie_id, 
    title, 
    production_year
ORDER BY 
    production_year DESC, 
    title;