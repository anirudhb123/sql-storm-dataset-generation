SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.kind AS company_type, 
    r.role AS role_description, 
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
    AND c.kind ILIKE '%production%'
GROUP BY 
    a.name, m.title, c.kind, r.role
ORDER BY 
    m.production_year DESC, a.name;
