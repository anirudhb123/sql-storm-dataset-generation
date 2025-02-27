
SELECT 
    c.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    r.role AS actor_role,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    cast_info ci
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON a.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.production_year BETWEEN 2000 AND 2023
GROUP BY 
    c.name, a.title, a.production_year, r.role
HAVING 
    COUNT(mk.keyword_id) > 5
ORDER BY 
    a.production_year DESC, c.name;
