SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.gender AS actor_gender,
    cn.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    name p ON ak.person_id = p.imdb_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.nr_order < 5
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
