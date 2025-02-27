SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    d.info AS director_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    COUNT(*) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_info d ON t.id = d.movie_id AND d.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, d.info, k.keyword, comp.name
ORDER BY 
    total_movies DESC
LIMIT 10;
