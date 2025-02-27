
SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword, 
    i.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    c.kind = 'Production'
AND 
    k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
