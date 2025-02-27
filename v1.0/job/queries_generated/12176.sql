SELECT 
    a.name AS akat_name, 
    t.title AS movie_title, 
    c.nr_order, 
    p.info AS person_info, 
    r.role AS person_role, 
    k.keyword AS movie_keyword 
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
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
