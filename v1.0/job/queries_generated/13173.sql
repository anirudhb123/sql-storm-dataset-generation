SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    t.production_year DESC, a.name;
