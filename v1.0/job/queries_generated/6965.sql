SELECT 
    n.name AS actor_name,
    COUNT(mi.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    AVG(CASE WHEN a.production_year IS NOT NULL THEN a.production_year ELSE NULL END) AS average_production_year,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name n ON an.id = n.id
LEFT JOIN 
    aka_title a ON a.id = t.id
WHERE 
    n.gender = 'F'
    AND a.production_year >= 2000
GROUP BY 
    n.name
ORDER BY 
    movie_count DESC
LIMIT 10;
