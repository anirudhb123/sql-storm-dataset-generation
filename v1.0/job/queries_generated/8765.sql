SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    c.name AS company_name,
    cp.kind AS company_type,
    p.info AS person_info
FROM
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    title t ON t.id = ci.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON c.id = mc.company_id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id
LEFT JOIN 
    role_type r ON r.id = ci.role_id
WHERE 
    t.production_year > 2000
    AND r.role IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.name, cp.kind, p.info
ORDER BY 
    t.production_year DESC, a.name;
