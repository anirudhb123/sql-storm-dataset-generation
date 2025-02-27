SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    r.role AS actor_role,
    c.production_year,
    c.note AS casting_note
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS n ON ci.person_id = n.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    keyword AS k ON t.id = k.id
WHERE 
    c.status_id = 1
ORDER BY 
    c.production_year DESC, 
    t.title;
