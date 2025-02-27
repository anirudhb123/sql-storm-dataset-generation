SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    ki.keyword AS movie_keyword,
    r.role AS person_role,
    p.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
