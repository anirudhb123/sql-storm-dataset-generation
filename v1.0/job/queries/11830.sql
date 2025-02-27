SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    k.keyword AS movie_keyword 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id 
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id 
JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
JOIN 
    comp_cast_type AS c ON ci.role_id = c.id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC, a.name;
