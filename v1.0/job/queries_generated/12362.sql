SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    cc.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cc ON mc.company_type_id = cc.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.name, t.title;
