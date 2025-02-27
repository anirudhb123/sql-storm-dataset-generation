SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.role_id AS role_id
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id AND ci.id = cc.subject_id
JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title, n.name;
