SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    pi.info AS actor_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, pi.info
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY 
    t.production_year DESC, a.name;
