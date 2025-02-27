-- Performance Benchmarking on Join Order Benchmark Schema
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    t.production_year,
    tk.keyword AS movie_keyword,
    cn.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
