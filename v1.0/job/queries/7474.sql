SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    cp.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND cp.kind LIKE '%Production%'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
