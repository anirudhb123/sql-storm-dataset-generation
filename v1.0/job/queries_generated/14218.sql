SELECT 
    t.title AS movie_title,
    n.name AS person_name,
    c.nr_order AS cast_order,
    ct.kind AS role_type,
    m.info AS movie_info
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS an ON c.person_id = an.person_id
JOIN 
    role_type AS ct ON c.role_id = ct.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, c.nr_order;
