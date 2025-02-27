SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    cct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
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
    company_type cct ON mc.company_type_id = cct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info = 'Budget'
GROUP BY 
    a.name, t.title, cct.kind
HAVING 
    num_companies > 1 AND AVG(m.production_year) BETWEEN 2000 AND 2023
ORDER BY 
    avg_production_year DESC;
