SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nq_order AS cast_order,
    p.name AS actor_name,
    ci.kind AS company_type,
    ki.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name p ON ak.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    ak.name LIKE '%Smith%' 
    AND t.production_year > 2000 
    AND ci.nr_order < 10
ORDER BY 
    t.production_year DESC, 
    ak.name, 
    ci.nr_order;
