SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    co.name AS company_name,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind, co.name, m.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    a.name, t.production_year DESC;
