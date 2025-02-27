SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS associated_keywords,
    COUNT(m.id) AS company_count,
    AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_presence
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.id, t.id
ORDER BY 
    t.production_year DESC, actor_name;
