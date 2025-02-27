SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    c.person_id,
    p.info AS person_info,
    ct.kind AS casting_type,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%action%'
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, a.name;
