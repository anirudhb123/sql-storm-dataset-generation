SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(m.id) AS total_movies 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND ci.nr_order < 5 
GROUP BY 
    a.name, t.title, company_type, k.keyword 
HAVING 
    COUNT(m.id) > 1 
ORDER BY 
    total_movies DESC;
