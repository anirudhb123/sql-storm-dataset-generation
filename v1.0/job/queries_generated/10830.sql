SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.kind AS comp_cast_type,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS i ON t.id = i.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
