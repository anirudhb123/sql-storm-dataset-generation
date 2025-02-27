SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    t.production_year DESC, 
    ci.nr_order;
