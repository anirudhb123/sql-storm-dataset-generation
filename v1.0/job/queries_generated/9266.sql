SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS performance_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND c.kind = 'Production'
GROUP BY 
    a.id, a.name, t.title, t.production_year, c.kind
ORDER BY 
    total_keywords DESC, t.production_year DESC;
