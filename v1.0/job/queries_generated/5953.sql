SELECT 
    t.title AS movie_title,
    c.name AS character_name,
    ak.name AS aka_name,
    comp.name AS company_name,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id AND ci.movie_id = t.id
JOIN 
    char_name ch ON ci.role_id = ch.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
    AND comp.country_code = 'USA'
    AND ak.name IS NOT NULL
ORDER BY 
    t.production_year DESC, t.title ASC;
