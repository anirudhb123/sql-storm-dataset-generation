SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    ct.kind AS comp_cast_type, 
    m.name AS company_name, 
    m.term AS company_type, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    a.imdb_index IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
ORDER BY 
    t.production_year DESC, 
    a.name;
