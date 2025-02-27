
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ARRAY_AGG(DISTINCT pi.info) AS person_info
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
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind IN ('Production', 'Distribution')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    t.production_year DESC, a.name;
