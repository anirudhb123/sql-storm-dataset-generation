SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_type, 
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords 
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS rt ON ci.role_id = rt.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
GROUP BY 
    a.name, t.title, c.kind 
ORDER BY 
    production_companies DESC, actor_name;
