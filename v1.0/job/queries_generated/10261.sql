SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mt.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    company_type AS mt ON mc.company_type_id = mt.id
JOIN 
    movie_info AS ti ON t.id = ti.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name ASC;
