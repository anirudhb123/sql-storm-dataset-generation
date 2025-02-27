SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role,
    c.kind AS comp_cast_type,
    COUNT(p.id) as total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_name cn ON m.company_id = cn.id
JOIN 
    comp_cast_type cc ON m.company_type_id = cc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE '%Smith%' 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, r.role, c.kind
HAVING 
    COUNT(p.id) > 5
ORDER BY 
    total_movies DESC;
