SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.note AS cast_note,
    r.role AS role_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON a.person_id = p.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword k ON t.id = k.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ct.kind IS NOT NULL
ORDER BY 
    a.name, t.production_year;
