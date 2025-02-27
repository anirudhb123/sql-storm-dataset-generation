SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = (SELECT mk.movie_id FROM movie_keyword mk WHERE mk.keyword_id = k.id)
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
