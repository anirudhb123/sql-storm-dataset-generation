SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS company_names,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND r.role IN ('Actor', 'Director', 'Producer')
GROUP BY 
    a.id, t.id, r.id
ORDER BY 
    t.production_year DESC, a.name;
