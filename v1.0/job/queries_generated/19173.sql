SELECT 
    t.title,
    a.name AS actor_name,
    ci.kind AS role_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
WHERE 
    t.production_year = 2022
ORDER BY 
    a.name;
