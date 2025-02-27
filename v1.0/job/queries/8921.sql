SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    n.name AS actor_name,
    co.name AS company_name,
    kt.keyword AS movie_keyword,
    m.info AS movie_info,
    ct.kind AS company_type,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year > 2000
AND 
    a.name IS NOT NULL 
AND 
    co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order;
