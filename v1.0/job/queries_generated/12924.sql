SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS cast_type,
    ci.name AS company_name,
    ki.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
