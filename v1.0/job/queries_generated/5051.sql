SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.name AS company_name,
    ci.kind AS company_type,
    COUNT(mi.info) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, m.name, ci.kind
ORDER BY 
    info_count DESC, a.name;
