SELECT 
    n.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    c.kind AS cast_type,
    COUNT(mc.id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_companies mc ON a.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.production_year >= 2000
    AND c.kind IS NOT NULL
GROUP BY 
    n.name, a.title, a.production_year, c.kind
ORDER BY 
    a.production_year DESC, actor_name;
