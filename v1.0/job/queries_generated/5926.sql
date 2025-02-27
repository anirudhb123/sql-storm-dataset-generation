SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    y.production_year, 
    k.keyword AS movie_keyword, 
    p.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title y ON t.id = y.id
LEFT JOIN 
    movie_keyword mk ON y.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    c.nr_order = 1 
    AND y.production_year >= 2000 
    AND k.keyword IS NOT NULL
ORDER BY 
    y.production_year DESC, 
    actor_name;
