SELECT 
    akn.name AS aka_name,
    ttl.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.note AS cast_note,
    c.nr_order AS cast_order
FROM 
    aka_name akn
JOIN 
    cast_info c ON akn.person_id = c.person_id
JOIN 
    title ttl ON c.movie_id = ttl.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    info_type i ON c.note = i.info
WHERE 
    ttl.production_year >= 2000
ORDER BY 
    ttl.production_year DESC, 
    c.nr_order ASC;
