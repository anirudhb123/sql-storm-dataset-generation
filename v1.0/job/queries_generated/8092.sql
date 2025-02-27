SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type,
    y.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword y ON mk.keyword_id = y.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year > 2000 
    AND c.kind LIKE 'Production%' 
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
