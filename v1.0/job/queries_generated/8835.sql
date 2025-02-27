SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    c.movie_id,
    c.person_id,
    p.name AS person_name,
    ct.kind AS company_type,
    cn.name AS company_name,
    k.keyword AS movie_keyword,
    ri.role AS person_role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type ri ON c.role_id = ri.id
JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1
WHERE 
    t.production_year >= 2000 
    AND a.name ILIKE '%Smith%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
