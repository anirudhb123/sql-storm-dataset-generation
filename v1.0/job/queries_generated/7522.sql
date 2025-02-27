SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type,
    i.info AS movie_info,
    COALESCE(SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END), 0) AS director_count,
    COALESCE(SUM(CASE WHEN r.role = 'Actor' THEN 1 ELSE 0 END), 0) AS actor_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.id, a.name, cn.name, ct.kind, i.info
HAVING 
    COUNT(DISTINCT a.id) > 5
ORDER BY 
    t.production_year DESC, actor_count DESC;
