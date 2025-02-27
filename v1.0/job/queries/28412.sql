
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_coactors
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
    AND r.role LIKE '%Lead%'
GROUP BY 
    a.name, m.title, m.production_year, r.role
ORDER BY 
    total_coactors DESC, m.production_year DESC
LIMIT 10;
