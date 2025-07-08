SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    tc.kind AS company_type, 
    c.name AS company_name, 
    mi.info AS movie_information, 
    k.keyword AS movie_keyword
FROM 
    aka_name a 
JOIN 
    cast_info ca ON a.person_id = ca.person_id 
JOIN 
    title t ON ca.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    company_type tc ON mc.company_type_id = tc.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'box office%') 
ORDER BY 
    t.production_year DESC, 
    a.name, 
    k.keyword;
