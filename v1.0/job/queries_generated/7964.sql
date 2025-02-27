SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies,
    GROUP_CONCAT(DISTINCT p.info ORDER BY p.info) AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
AND 
    p.info_type_id IN (SELECT id FROM info_type WHERE info = 'birthdate')
GROUP BY 
    a.name, t.title
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    t.production_year DESC, a.name ASC;
