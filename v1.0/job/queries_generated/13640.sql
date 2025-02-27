SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
ORDER BY 
    a.name, t.title, c.nr_order;
