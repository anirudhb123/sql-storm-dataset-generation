SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
INNER JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
INNER JOIN 
    company_name AS co ON mc.company_id = co.id
INNER JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
