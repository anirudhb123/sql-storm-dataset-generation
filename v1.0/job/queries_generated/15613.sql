SELECT 
    t.title, 
    a.name AS actor_name, 
    ct.kind AS character_type
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title;
