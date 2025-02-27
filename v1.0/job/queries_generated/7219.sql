SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ct.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.role_id, ct.kind
ORDER BY 
    a.name, t.title;
