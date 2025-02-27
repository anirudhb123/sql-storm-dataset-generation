SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT p.info) AS person_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    actor_name, movie_title;
