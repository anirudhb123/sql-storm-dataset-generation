SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    COUNT(*) AS appearances 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    company_name cn ON mi.info = cn.name 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
AND 
    cn.country_code = 'USA' 
GROUP BY 
    a.name, t.title, c.kind 
HAVING 
    COUNT(*) > 5 
ORDER BY 
    appearances DESC 
LIMIT 10;
