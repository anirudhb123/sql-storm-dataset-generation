SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ci.nr_order AS cast_order
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, ci.nr_order;
