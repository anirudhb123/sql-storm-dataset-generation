SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = m.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = m.id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE '%Smith%' 
    AND m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, a.name ASC
LIMIT 
    100;
