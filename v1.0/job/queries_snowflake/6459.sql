SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    aka_title t ON ca.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind LIKE '%Production%'
ORDER BY 
    t.production_year DESC,
    a.name;
