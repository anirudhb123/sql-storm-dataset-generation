SELECT 
    a.name AS person_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.title IS NOT NULL 
    AND ct.kind IS NOT NULL
ORDER BY 
    a.name, t.title;
