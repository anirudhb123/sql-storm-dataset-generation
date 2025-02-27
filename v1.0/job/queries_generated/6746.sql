SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_info AS m ON t.movie_id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.movie_id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    AND a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
