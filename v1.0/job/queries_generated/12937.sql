SELECT 
    t.title,
    a.name AS actor_name,
    ci.note AS character_note,
    c.name AS company_name,
    mt.kind AS company_type,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
ORDER BY 
    t.title, a.name;
