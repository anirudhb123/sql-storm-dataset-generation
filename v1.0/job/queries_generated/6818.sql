SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name) AS company_names,
    rt.role AS role_type
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
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
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    p.name, t.title, t.production_year, rt.role
ORDER BY 
    t.production_year DESC, actor_name;
