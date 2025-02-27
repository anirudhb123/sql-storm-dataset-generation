SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT c.id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    title t ON ca.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, ct.kind, k.keyword
HAVING 
    COUNT(DISTINCT cn.id) > 1
ORDER BY 
    actor_name, movie_title;
