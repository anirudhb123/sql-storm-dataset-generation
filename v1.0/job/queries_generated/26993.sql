SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT c2.role_id) AS num_roles
FROM 
    aka_name a
JOIN 
    cast_info c2 ON a.person_id = c2.person_id
JOIN 
    title t ON c2.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.id, t.id
ORDER BY 
    a.actor_name, t.production_year DESC
LIMIT 50;

