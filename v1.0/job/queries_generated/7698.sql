SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT p.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT p.id) > 5
ORDER BY 
    total_movies DESC;
