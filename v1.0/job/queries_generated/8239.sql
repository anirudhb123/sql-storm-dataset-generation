SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    COUNT(mv.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year >= 2000
AND 
    mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(mv.id) > 1
ORDER BY 
    total_movies DESC, a.name ASC;
