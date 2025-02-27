SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS cast_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, actor_name;
