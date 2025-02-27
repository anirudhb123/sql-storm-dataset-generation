SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    pc.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000
    AND ct.kind ILIKE 'Production%'
ORDER BY 
    a.name, t.production_year DESC, c.nr_order;
