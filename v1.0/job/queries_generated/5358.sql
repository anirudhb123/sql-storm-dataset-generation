SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT mc.id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(mi.info) AS movie_info,
    COUNT(DISTINCT c.person_role_id) AS role_count
FROM 
    title t 
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name
ORDER BY 
    company_count DESC, role_count DESC
LIMIT 100;
