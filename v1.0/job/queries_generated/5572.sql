SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    m.production_year,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
AND 
    r.role = 'Actor'
GROUP BY 
    t.title, a.name, r.role, c.name, m.production_year
ORDER BY 
    keyword_count DESC, m.production_year DESC;
