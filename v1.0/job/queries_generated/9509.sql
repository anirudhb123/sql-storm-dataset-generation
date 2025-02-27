SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    c.kind AS company_type, 
    COUNT(DISTINCT i.id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT i.id) > 1 
ORDER BY 
    t.production_year DESC, actor_name ASC;
