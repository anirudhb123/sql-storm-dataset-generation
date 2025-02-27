SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.name AS person_name,
    r.role AS role_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p_info ON a.person_id = p_info.person_id
LEFT JOIN 
    info_type i ON p_info.info_type_id = i.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name ILIKE '%John%'
    AND k.keyword IN ('Action', 'Drama', 'Comedy')
ORDER BY 
    t.production_year DESC, 
    cast_order, 
    aka_name;
