SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    cm.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000
    AND kt.keyword ILIKE '%action%'
ORDER BY 
    a.name, t.production_year DESC
LIMIT 100;
