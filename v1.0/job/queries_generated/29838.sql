SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title_name,
    t.production_year,
    c.person_role_id,
    r.role AS person_role,
    p.info AS person_info,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND a.name LIKE 'A%'
GROUP BY 
    a.id, t.id, c.person_role_id, r.role, p.info
ORDER BY 
    aka_name ASC, title_name ASC;
