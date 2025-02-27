SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(GROUP_CONCAT(DISTINCT c.name ORDER BY c.name), 'Unknown') AS companies,
    r.role AS role_description,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND r.role IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name;
