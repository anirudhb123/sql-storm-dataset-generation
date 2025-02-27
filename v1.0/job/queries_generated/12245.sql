SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    ci.kind AS cast_type,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
