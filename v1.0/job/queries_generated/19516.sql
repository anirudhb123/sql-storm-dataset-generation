SELECT 
    t.title, 
    a.name AS actor_name, 
    p.info AS actor_info 
FROM 
    aka_title AS t 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    cast_info AS ci ON t.id = ci.movie_id 
JOIN 
    aka_name AS a ON ci.person_id = a.person_id 
JOIN 
    person_info AS p ON a.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.title;
