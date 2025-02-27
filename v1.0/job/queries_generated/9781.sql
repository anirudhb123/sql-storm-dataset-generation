SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.company_name AS production_company,
    rt.role AS role_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year > 2000
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, c.company_name, rt.role
ORDER BY 
    keyword_count DESC, t.production_year DESC;
