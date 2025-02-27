SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    c.name AS company_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, ct.kind, c.name
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    t.production_year DESC, actor_name;
