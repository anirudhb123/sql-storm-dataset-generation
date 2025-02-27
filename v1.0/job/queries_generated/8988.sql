SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    c.kind AS comp_type, 
    COUNT(m.id) AS company_count 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND c.kind IS NOT NULL 
GROUP BY 
    a.name, t.title, c.kind 
HAVING 
    COUNT(m.id) > 1 
ORDER BY 
    actor_name, movie_title;
