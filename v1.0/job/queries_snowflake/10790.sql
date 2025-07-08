SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.role_id,
    COUNT(*) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    a.name, m.title, m.production_year, c.role_id
ORDER BY 
    total_roles DESC;
