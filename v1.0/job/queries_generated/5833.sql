SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    r.role AS role_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
GROUP BY 
    a.name, t.title, t.production_year, c.role_id, r.role 
ORDER BY 
    t.production_year DESC, a.name;
