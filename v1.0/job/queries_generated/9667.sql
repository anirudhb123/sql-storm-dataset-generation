SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND co.country_code = 'USA'
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
