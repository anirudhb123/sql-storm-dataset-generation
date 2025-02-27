
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS companies,
    COUNT(DISTINCT ci.id) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.role_id) > 2
ORDER BY 
    t.production_year DESC, a.name;
