SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT g.kind ORDER BY g.kind) AS genres,
    m.name AS production_company,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT p.info) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type p ON mi.info_type_id = p.id
LEFT JOIN 
    kind_type g ON t.kind_id = g.id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, m.name
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    t.production_year DESC, a.name;
