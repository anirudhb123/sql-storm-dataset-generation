SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    pe.info AS person_info,
    kt.keyword AS movie_keyword,
    c.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info pe ON a.person_id = pe.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC;
