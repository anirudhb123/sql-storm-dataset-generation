SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
    COUNT(mcc.company_id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mcc ON t.id = mcc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.id, t.id, c.kind, t.production_year
HAVING 
    COUNT(mcc.company_id) > 0
ORDER BY 
    t.production_year DESC, a.name;
