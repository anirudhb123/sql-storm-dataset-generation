SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    movie_keyword AS mk ON c.movie_id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.title IS NOT NULL
    AND p.info_type_id = 1
ORDER BY 
    c.nr_order, t.production_year DESC;
