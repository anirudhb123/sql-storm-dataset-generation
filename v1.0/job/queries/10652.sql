SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    pn.name AS person_name,
    ci.kind AS company_type,
    kw.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    name pn ON a.person_id = pn.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
