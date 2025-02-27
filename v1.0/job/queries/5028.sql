
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_kind,
    COUNT(*) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code IN ('US', 'UK')
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    role_count DESC, actor_name ASC
LIMIT 50;
