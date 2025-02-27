SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS cast_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    kind_type kt ON t.kind_id = kt.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    a.name LIKE '%Smith%' 
    AND t.production_year > 2000 
    AND kt.kind = 'feature'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
