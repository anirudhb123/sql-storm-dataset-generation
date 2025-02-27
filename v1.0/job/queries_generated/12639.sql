SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    m.company_id AS production_company
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_keyword k ON t.id = k.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, c.nr_order;
