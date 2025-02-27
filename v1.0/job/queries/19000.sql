SELECT 
    t.title, 
    a.name AS actor_name, 
    i.info AS movie_info 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    aka_name a ON cc.subject_id = a.person_id 
JOIN 
    movie_info i ON t.id = i.movie_id 
WHERE 
    t.production_year >= 2000 
    AND c.country_code = 'USA';
