
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS companies
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor')
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
