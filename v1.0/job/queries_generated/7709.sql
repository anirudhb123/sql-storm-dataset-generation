SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS actor_role, 
    c.note AS cast_note, 
    m.info AS movie_info, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    cn.name AS company_name, 
    ct.kind AS company_type, 
    COUNT(DISTINCT mc.movie_id) AS total_movie_companies 
FROM 
    title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON a.person_id = c.person_id 
JOIN 
    role_type r ON r.id = c.role_id 
LEFT JOIN 
    movie_info m ON m.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id 
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id 
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id 
WHERE 
    t.production_year > 2000 
GROUP BY 
    t.title, a.name, r.role, c.note, m.info, cn.name, ct.kind 
ORDER BY 
    t.title, a.name;
