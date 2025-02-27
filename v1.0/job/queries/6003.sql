
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT k.keyword) AS num_keywords
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    title t ON ci.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 AND 
    a.name LIKE 'A%' 
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    num_companies DESC, num_keywords DESC
LIMIT 10;
