SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    COUNT(m.id) AS movie_count
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
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
    AND mi.info LIKE '%million%'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    movie_count DESC
LIMIT 10;
