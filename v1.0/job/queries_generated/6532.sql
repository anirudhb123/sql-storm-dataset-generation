SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    count(DISTINCT m.id) AS total_movies,
    avg(m.production_year) AS average_production_year
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
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Production Budget')
    AND mi.info IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    count(DISTINCT m.id) > 5
ORDER BY 
    total_movies DESC, average_production_year ASC
LIMIT 20;
