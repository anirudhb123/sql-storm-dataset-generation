SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    ct.kind AS company_type,
    mk.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year > 2000
    AND ct.kind = 'Production'
    AND mk.keyword IN ('Drama', 'Thriller')
ORDER BY 
    t.production_year DESC, ak.name ASC;
