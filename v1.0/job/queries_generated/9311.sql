SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
GROUP BY 
    t.id, a.id, c.id, p.id
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    t.production_year DESC, a.name ASC;
