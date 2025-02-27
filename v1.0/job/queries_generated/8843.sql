SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    c.nr_order AS role_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    MIN(m.production_year) AS earliest_production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
    AND t.production_year > 2000
GROUP BY 
    t.title, a.name, c.kind, c.nr_order, co.name, k.keyword
HAVING 
    COUNT(mk.id) > 1
ORDER BY 
    earliest_production_year DESC, movie_title ASC;
