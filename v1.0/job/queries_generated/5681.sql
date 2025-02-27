SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_kind,
    COUNT(DISTINCT m.id) AS num_of_movies,
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
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    a.name IS NOT NULL
    AND c.kind IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    num_of_movies DESC, avg_production_year ASC
LIMIT 10;
