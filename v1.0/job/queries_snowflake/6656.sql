
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT m.company_id) AS company_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
cast_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
complete_info AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        cr.role,
        cr.actor_count,
        md.company_count,
        md.keywords
    FROM 
        movie_details md
    LEFT JOIN 
        cast_roles cr ON md.movie_id = cr.movie_id
)
SELECT 
    ci.movie_id,
    ci.title,
    ci.production_year,
    ci.role,
    ci.actor_count,
    ci.company_count,
    ci.keywords
FROM 
    complete_info ci
WHERE 
    ci.production_year > 2000
ORDER BY 
    ci.production_year DESC, 
    ci.company_count DESC, 
    ci.actor_count DESC
LIMIT 100;
