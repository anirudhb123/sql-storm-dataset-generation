SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
