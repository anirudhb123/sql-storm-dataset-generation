SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    rt.role AS role_name,
    c.note AS cast_note,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.name ILIKE '%Smith%'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, p.name ASC;
