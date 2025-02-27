SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name_pcode_cf IS NOT NULL 
    AND t.production_year > 2000 
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    total_movies > 1
ORDER BY 
    avg_production_year DESC, a.name ASC;
