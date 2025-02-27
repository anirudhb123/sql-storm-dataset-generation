SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_info_id,
    c.note AS cast_note,
    n.id AS person_id,
    n.name AS person_name,
    co.name AS company_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
