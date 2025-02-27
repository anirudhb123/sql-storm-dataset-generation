SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    co.name AS company_name,
    ki.keyword AS keywords,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE 'John%'
    AND t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order < 5
ORDER BY 
    t.production_year DESC, 
    a.name;
