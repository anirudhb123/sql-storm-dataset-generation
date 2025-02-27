SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.role_id AS role_id,
    k.keyword AS movie_keyword,
    c.nr_order AS cast_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    c.nr_order ASC;
