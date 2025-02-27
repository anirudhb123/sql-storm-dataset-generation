
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT c.person_role_id) AS num_roles,
    MAX(r.role) AS primary_role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, m.title, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
