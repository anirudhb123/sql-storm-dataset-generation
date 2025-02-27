
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.production_year,
    COUNT(DISTINCT m.id) AS movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON m.id = t.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND c.kind LIKE 'Production%'
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    movie_count DESC, m.production_year DESC
LIMIT 100;
