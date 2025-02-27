SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    ct.kind AS cast_type, 
    c.name AS company_name, 
    COUNT(DISTINCT mi.info) AS info_count
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
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Acting'
    AND c.country_code IN ('USA', 'GB')
GROUP BY 
    a.name, t.title, t.production_year, ct.kind, c.name
ORDER BY 
    info_count DESC, a.name, t.production_year DESC;
