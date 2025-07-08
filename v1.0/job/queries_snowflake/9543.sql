SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.role_id AS role_id, 
    ct.kind AS company_type, 
    p.info AS person_info, 
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year > 2000 
    AND ct.kind LIKE '%Production%'
GROUP BY 
    a.name, m.title, c.role_id, ct.kind, p.info
ORDER BY 
    movie_count DESC
LIMIT 10;
