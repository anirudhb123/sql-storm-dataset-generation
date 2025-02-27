SELECT 
    p.name AS person_name,
    m.title AS movie_title,
    c.nr_order,
    r.role,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, c.nr_order;
