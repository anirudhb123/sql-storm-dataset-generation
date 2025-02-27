SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    m.production_year,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.id, a.id, r.id
ORDER BY 
    m.production_year DESC, t.title;
