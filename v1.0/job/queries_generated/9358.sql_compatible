
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    ti.info AS movie_info,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(t.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    a.name LIKE 'A%'
GROUP BY 
    a.name, t.title, c.kind, ti.info, t.production_year
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    avg_production_year DESC, total_movies DESC;
