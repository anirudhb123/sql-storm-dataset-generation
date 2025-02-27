SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    c.nr_order AS role_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2020
    AND c.nr_order < 5
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
