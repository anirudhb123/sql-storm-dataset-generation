SELECT 
    c.id AS cast_id,
    p.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS role_type,
    m.year AS production_year,
    k.keyword AS movie_keyword
FROM 
    cast_info c 
JOIN 
    aka_name p ON c.person_id = p.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type ct ON c.role_id = ct.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1) 
    AND t.production_year BETWEEN 2000 AND 2023 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC 
LIMIT 100;
