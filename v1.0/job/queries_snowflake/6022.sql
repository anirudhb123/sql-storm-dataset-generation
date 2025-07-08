SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    ct.kind AS company_type, 
    gm.info AS genre_info
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN 
    movie_info gm ON t.id = gm.movie_id AND gm.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') 
WHERE 
    t.production_year >= 2000 
    AND ct.kind = 'Distributor' 
ORDER BY 
    a.name, 
    t.title;
