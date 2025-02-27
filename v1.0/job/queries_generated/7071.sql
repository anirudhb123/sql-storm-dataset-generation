SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    co.name AS company_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    mi.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, co.name, mi.info
HAVING 
    COUNT(DISTINCT mk.keyword) > 3
ORDER BY 
    a.name, t.production_year DESC;
