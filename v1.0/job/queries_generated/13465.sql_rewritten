SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.gender AS person_gender,
    c.role_id AS cast_role_id,
    comp.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON c.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
    AND ak.name IS NOT NULL
ORDER BY 
    t.production_year DESC, t.title;