SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title AS t
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_info AS i ON t.id = i.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
