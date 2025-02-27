WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
        AND t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year, a.name
), actor_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT(n.name, ' as ', r.role), '; ') AS actor_roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.director_name,
    md.keywords,
    ar.actor_roles
FROM 
    movie_details md
LEFT JOIN 
    actor_roles ar ON md.movie_id = ar.movie_id
ORDER BY 
    md.production_year DESC, md.title;
