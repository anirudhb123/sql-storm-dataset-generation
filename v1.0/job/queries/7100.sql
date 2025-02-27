SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.kind AS comp_cast_type,
    co.name AS company_name,
    p.info AS person_info 
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON cc.subject_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
