SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    COUNT(*) AS role_count,
    AVG(mi.production_year) AS average_production_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name cn ON mi.note LIKE CONCAT('%', cn.id, '%')
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.role IN ('Actor', 'Actress')
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    role_count DESC, average_production_year ASC
LIMIT 100;
