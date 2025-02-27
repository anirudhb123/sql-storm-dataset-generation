SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role AS actor_role,
    GROUP_CONCAT(DISTINCT co.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, c.role
ORDER BY 
    t.production_year DESC;
