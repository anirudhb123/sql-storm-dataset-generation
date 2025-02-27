SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    r.role AS role_type, 
    c.name AS company_name 
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
WHERE 
    c.country_code = 'USA' 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND r.role LIKE '%actor%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
