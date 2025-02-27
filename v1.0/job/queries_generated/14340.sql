-- Performance Benchmark Query Example
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    k.keyword AS genre_keyword,
    m.info AS movie_info,
    cn.name AS company_name
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
