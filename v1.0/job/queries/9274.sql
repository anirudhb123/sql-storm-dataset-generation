SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    ci.nr_order AS role_order, 
    rt.role AS role_description, 
    COUNT(DISTINCT mc.company_id) AS production_company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND rt.role IN ('Actor', 'Director')
GROUP BY 
    a.name, t.title, t.production_year, ci.nr_order, rt.role
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    t.production_year DESC, a.name;
