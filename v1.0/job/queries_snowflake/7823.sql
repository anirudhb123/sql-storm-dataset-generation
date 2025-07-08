SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
    ct.kind AS company_type, 
    k.keyword AS movie_keyword 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    title AS t ON c.movie_id = t.id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
JOIN 
    person_info AS p ON a.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND ct.kind = 'Production' 
    AND k.keyword LIKE '%Drama%' 
ORDER BY 
    a.name, t.production_year DESC, c.nr_order;
