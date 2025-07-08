SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id AS character_role,
    ct.kind AS company_type,
    COUNT(*) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    a.name, t.title, t.production_year, c.role_id, ct.kind
ORDER BY 
    total_roles DESC;
