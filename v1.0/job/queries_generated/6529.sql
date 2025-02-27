SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    a2.name AS character_name,
    ki.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    char_name a2 ON cc.subject_id = a2.imdb_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year > 2000 
    AND c.kind = 'Distributor'
ORDER BY 
    a.name, t.title;
