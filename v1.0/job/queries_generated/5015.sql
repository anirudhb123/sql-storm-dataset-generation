SELECT 
    n.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    c.kind AS cast_type,
    co.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
JOIN 
    movie_companies mc ON a.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON a.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    a.production_year > 2000
    AND co.country_code = 'USA'
    AND kt.keyword ILIKE '%action%'
ORDER BY 
    a.production_year DESC, 
    n.name ASC;
