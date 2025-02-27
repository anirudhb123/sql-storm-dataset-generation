SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_info_id,
    c.note AS cast_note,
    ci.id AS company_id,
    ci.name AS company_name,
    ki.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    title t ON at.id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.id, t.production_year DESC;
