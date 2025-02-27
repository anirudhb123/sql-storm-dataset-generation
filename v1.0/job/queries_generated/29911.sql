SELECT 
    t.title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types,
    p.info AS person_info,
    COUNT(DISTINCT mc.id) AS company_count
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
GROUP BY 
    t.title, a.name, p.info
HAVING 
    COUNT(DISTINCT mc.id) > 1
ORDER BY 
    t.title ASC, a.name ASC;
