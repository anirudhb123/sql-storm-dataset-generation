SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ci.note AS cast_note,
    ct.kind AS cast_type,
    c.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name p ON ci.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
