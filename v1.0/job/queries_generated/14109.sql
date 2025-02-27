SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    p.info AS person_info,
    ct.kind AS company_type,
    kw.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC
LIMIT 100;
