SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS person_info,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
WHERE 
    t.production_year >= 2000 AND
    r.role LIKE '%actor%' AND
    co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
