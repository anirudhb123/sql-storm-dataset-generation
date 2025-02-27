-- Performance Benchmarking Query
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS year,
    r.role AS role_name,
    GROUP_CONCAT(DISTINCT c.kind) AS company_kinds,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name;
