SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_id,
    n.name AS person_name,
    r.role AS role_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name n ON ci.person_id = n.imdb_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name co ON mi.info LIKE '%' || co.name || '%'
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
