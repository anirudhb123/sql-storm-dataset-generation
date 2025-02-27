-- Performance Benchmarking SQL Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_role,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    title t
JOIN 
    aka_title AT ON t.id = AT.movie_id
JOIN 
    cast_info ci ON AT.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    m.production_year > 2000
GROUP BY 
    t.title, a.name, c.kind, m.production_year
ORDER BY 
    m.production_year DESC;
