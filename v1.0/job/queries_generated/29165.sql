SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT c.kind SEPARATOR ', ') AS company_types,
    p.info AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id
WHERE 
    m.production_year >= 2000
    AND a.name IS NOT NULL
    AND ci.nr_order < 5
GROUP BY 
    a.name, m.title, m.production_year, p.info
ORDER BY 
    keyword_count DESC, m.production_year DESC;
