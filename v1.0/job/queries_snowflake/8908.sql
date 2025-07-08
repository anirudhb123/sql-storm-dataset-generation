SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    y.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(*) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title y ON t.id = y.id
WHERE 
    a.name IS NOT NULL 
    AND y.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, y.production_year, c.kind, k.keyword
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_roles DESC, a.name;
