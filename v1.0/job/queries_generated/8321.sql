WITH movie_actor_roles AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        a.name AS actor_name,
        r.role AS actor_role,
        COUNT(ci.id) AS total_appearances
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        t.id, t.title, a.name, r.role
),
company_movie_info AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS total_movies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    ma.movie_id,
    ma.movie_title,
    ma.actor_name,
    ma.actor_role,
    ma.total_appearances,
    cm.company_name,
    cm.company_type,
    cm.total_movies
FROM 
    movie_actor_roles ma
LEFT JOIN 
    complete_cast mc ON ma.movie_id = mc.movie_id
LEFT JOIN 
    company_movie_info cm ON ma.movie_id = cm.movie_id
WHERE 
    ma.total_appearances > 1 AND cm.total_movies > 5
ORDER BY 
    ma.total_appearances DESC, 
    cm.total_movies DESC
LIMIT 100;
