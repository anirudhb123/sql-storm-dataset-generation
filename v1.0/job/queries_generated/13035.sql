SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    cp.kind AS company_type,
    mt.info AS movie_info
FROM 
    title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS cp ON mc.company_type_id = cp.id
JOIN 
    movie_info AS mt ON t.id = mt.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, c.nr_order;
