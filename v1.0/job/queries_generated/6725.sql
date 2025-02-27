SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS role, 
    k.keyword AS keyword, 
    ci.name AS company_name, 
    i.info AS movie_info 
FROM 
    title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON a.person_id = c.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name ci ON mc.company_id = ci.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type i ON mi.info_type_id = i.id 
WHERE 
    t.production_year > 2000 
    AND k.keyword LIKE '%action%' 
    AND c.nr_order < 5 
ORDER BY 
    t.title, a.name;
