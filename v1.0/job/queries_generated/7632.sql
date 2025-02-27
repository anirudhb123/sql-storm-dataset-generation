SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    p.info AS person_bio,
    k.keyword AS movie_keyword,
    c.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name ILIKE '%Smith%' 
    AND t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%bio%')
ORDER BY 
    t.production_year DESC, 
    a.name;
