SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    rt.role AS role,
    cnt.name AS company_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND cnt.country_code = 'USA'
GROUP BY 
    a.id, t.id, rt.id, cnt.id
ORDER BY 
    t.production_year DESC, keyword_count DESC
LIMIT 
    100;
