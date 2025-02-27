SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS role_type,
    m.prod_year AS production_year,
    COUNT(*) AS role_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
GROUP BY 
    t.title, ak.name, c.kind, m.production_year
ORDER BY 
    role_count DESC, m.prod_year ASC;
