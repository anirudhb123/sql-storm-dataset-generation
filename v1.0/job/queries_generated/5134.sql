SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.company_name AS production_company,
    g.kind AS genre,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    kind_type g ON t.kind_id = g.id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    g.kind = 'Action' 
    AND i.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
