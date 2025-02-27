SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year = 2023
ORDER BY 
    c.nr_order;
