SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    COUNT(m.movie_id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.name, k.keyword
HAVING 
    COUNT(m.movie_id) > 1
ORDER BY 
    movie_count DESC, a.name ASC;
