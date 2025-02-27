SELECT 
    t.title, 
    ak.name AS actor_name, 
    p.info AS person_info 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title;
