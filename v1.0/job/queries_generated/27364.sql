SELECT 
    t.title AS movie_title,
    t.production_year,
    ak.name AS actor_name,
    r.role AS actor_role,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    p.info AS person_info,
    COUNT(DISTINCT mk.id) AS keyword_count
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword ILIKE '%action%'
    AND ci.nr_order < 5
GROUP BY 
    t.title, t.production_year, ak.name, r.role, k.keyword, c.name, p.info
ORDER BY 
    t.production_year DESC,
    COUNT(DISTINCT mk.id) DESC;
