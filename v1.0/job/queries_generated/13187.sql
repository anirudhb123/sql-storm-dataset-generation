SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ci.nr_order AS cast_order,
    c.kind AS company_type,
    mt.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mt ON t.id = mt.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON ci.person_id = p.imdb_id
WHERE 
    t.production_year > 2000
ORDER BY 
    ak.name, t.title;
