
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type, 
    k.keyword AS movie_keyword, 
    p.info AS person_info, 
    COUNT(DISTINCT c.person_id) AS total_casts
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    keyword k ON t.id = k.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
    AND ct.kind LIKE '%production%' 
GROUP BY 
    a.name, t.title, ct.kind, k.keyword, p.info 
ORDER BY 
    total_casts DESC, t.title ASC 
LIMIT 50;
