SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    pi.info AS actor_info
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
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, pi.info
ORDER BY 
    t.production_year DESC, actor_name;
