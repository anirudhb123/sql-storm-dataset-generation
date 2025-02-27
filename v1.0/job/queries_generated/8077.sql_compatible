
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS company_type, 
    COUNT(DISTINCT t.id) AS movie_count
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
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND ci.nr_order = 1
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    movie_count DESC, t.production_year ASC;
