SELECT 
    t.title,
    c.name AS actor_name,
    r.role AS role,
    m.production_year,
    k.keyword
FROM 
    title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS an ON ci.person_id = an.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_link AS ml ON t.id = ml.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC;
