SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies,
    COUNT(DISTINCT p.id) AS person_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    m.production_year >= 2000 
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
GROUP BY 
    a.id, m.id
ORDER BY 
    m.production_year DESC, a.name;
