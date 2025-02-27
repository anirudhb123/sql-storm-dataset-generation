SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON a.person_id = ci.person_id
JOIN 
    person_info AS p ON p.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id
JOIN 
    keyword AS k ON k.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
