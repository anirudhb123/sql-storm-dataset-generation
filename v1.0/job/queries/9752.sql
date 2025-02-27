WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
actor_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
),
extended_info AS (
    SELECT 
        md.movie_title,
        md.production_year,
        at.actor_name,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
    FROM 
        movie_details md
    JOIN 
        actor_titles at ON md.movie_title = at.movie_title AND md.production_year = at.production_year
    GROUP BY 
        md.movie_title, md.production_year, at.actor_name
)
SELECT 
    ei.actor_name,
    ei.movie_title,
    ei.production_year,
    ei.keywords
FROM 
    extended_info ei
WHERE 
    ei.production_year >= 2000
ORDER BY 
    ei.production_year DESC, ei.actor_name;
