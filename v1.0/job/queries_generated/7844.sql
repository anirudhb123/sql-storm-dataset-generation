SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    COUNT(DISTINCT kc.keyword) AS keyword_count, 
    GROUP_CONCAT(DISTINCT cn.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
GROUP BY 
    a.name, 
    t.title, 
    t.production_year
ORDER BY 
    t.production_year DESC, 
    keyword_count DESC;
