SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    r.role AS role_name,
    k.keyword AS movie_keyword,
    l.link AS movie_link_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_link ml ON t.id = ml.movie_id
JOIN 
    link_type l ON ml.link_type_id = l.id
WHERE 
    a.name IS NOT NULL 
ORDER BY 
    a.name, t.title;
