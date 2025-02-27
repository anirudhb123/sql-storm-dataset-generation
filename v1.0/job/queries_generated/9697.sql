SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_role, 
    m.production_year, 
    GROUP_CONCAT(DISTINCT co.name) AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info LIKE '%Academy Award%'
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(DISTINCT co.id) >= 2
ORDER BY 
    m.production_year DESC, actor_name;
