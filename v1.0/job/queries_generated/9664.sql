SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_role, 
    m.name AS company_name, 
    kw.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    t.production_year >= 2000 
    AND c.nr_order < 5 
    AND m.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
