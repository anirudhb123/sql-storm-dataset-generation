SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    ci.nr_order AS order_in_cast,
    co.name AS company_name,
    ti.production_year AS production_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    ti.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ti.production_year DESC, 
    ak.name;
