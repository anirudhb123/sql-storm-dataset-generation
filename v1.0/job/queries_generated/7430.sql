SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(m.production_year) AS average_production_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000 
    AND c.country_code = 'USA'
GROUP BY 
    t.title, a.name, r.role, c.name
ORDER BY 
    keyword_count DESC, average_production_year ASC
LIMIT 50;
