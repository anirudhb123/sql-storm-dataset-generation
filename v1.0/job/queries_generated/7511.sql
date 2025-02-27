SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(ci.id) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year > 2000 AND
    k.keyword IS NOT NULL
GROUP BY 
    a.id, t.id
ORDER BY 
    t.production_year DESC, role_count DESC
LIMIT 100;
