SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.info AS movie_info,
    GROUP_CONCAT(k.keyword) AS keywords
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
    movie_info m ON t.id = m.movie_id 
JOIN 
    keyword k ON t.id = k.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    AND c.kind IN ('Distributor', 'Production')
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    t.production_year DESC, a.name;
