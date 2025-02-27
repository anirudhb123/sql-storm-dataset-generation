SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    kt.keyword AS movie_keyword,
    ci.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
ORDER BY 
    t.production_year DESC, ak.name;
