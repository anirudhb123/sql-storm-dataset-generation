SELECT 
    t.id AS title_id,
    t.title AS title,
    t.production_year,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.name AS company_name,
    mk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
ORDER BY 
    t.production_year DESC, 
    t.title ASC;
