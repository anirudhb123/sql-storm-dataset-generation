SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    c.nr_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON c.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (1, 2)
ORDER BY 
    t.production_year DESC, 
    a.name;
