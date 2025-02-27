SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS actor_role,
    c.kind AS company_type,
    COUNT(mk.keyword) AS keyword_count
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 AND
    c.kind = 'Distributor'
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind
ORDER BY 
    keyword_count DESC, t.production_year DESC;
