SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ARRAY_AGG(DISTINCT p.info) AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
  AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    a.name, t.title;
