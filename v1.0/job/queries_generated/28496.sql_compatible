
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.info AS actor_info,
        r.role AS actor_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        person_info p ON c.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
    JOIN 
        role_type r ON c.person_role_id = r.id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    mc.actor_name,
    mc.actor_info,
    mc.actor_role,
    md.keywords,
    md.production_companies
FROM 
    movie_details md
JOIN 
    movie_cast mc ON md.movie_id = mc.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    mc.actor_name;
