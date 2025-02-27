SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.name AS company_name, 
    ci.role_id AS role_identifier, 
    COUNT(DISTINCT m.id) AS movie_count, 
    AVG(m.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON mi.movie_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
GROUP BY 
    a.id, a.name, t.title, c.name, ci.role_id
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    avg_production_year DESC, movie_count DESC;
