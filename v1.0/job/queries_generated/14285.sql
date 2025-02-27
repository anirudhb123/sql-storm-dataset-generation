SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_id,
    c.movie_id,
    p.id AS person_info_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.id;
