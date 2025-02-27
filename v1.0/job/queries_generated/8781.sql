SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    cn.name AS company_name,
    kt.keyword AS movie_keyword,
    k.kind AS kind_of_movie,
    r.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
    AND kt.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, ak.name;
