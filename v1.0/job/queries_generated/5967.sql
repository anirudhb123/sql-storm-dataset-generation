SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS character_id,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ci.kind AS company_type,
    mi.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND a.name IS NOT NULL
    AND c.nr_order IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC;
