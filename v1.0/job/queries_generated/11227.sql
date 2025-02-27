-- SQL Query for Performance Benchmarking using the Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    m.name AS production_company,
    tk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
