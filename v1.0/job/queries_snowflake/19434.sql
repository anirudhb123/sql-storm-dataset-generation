SELECT 
    t.title, 
    ak.name AS actor_name, 
    c.name AS company_name 
FROM 
    title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
WHERE 
    t.production_year = 2023 
ORDER BY 
    t.title;
