SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword,
    r.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC;
