SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT g.kind) AS genres,
    GROUP_CONCAT(DISTINCT c.name) AS companies,
    COUNT(mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    kind_type g ON t.kind_id = g.id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.id, t.id
ORDER BY 
    keyword_count DESC, t.production_year DESC;
