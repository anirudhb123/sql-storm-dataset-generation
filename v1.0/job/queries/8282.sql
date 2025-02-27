
SELECT 
    an.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND c.kind IN ('Distributor', 'Production')
GROUP BY 
    an.name, t.title, c.kind
HAVING 
    COUNT(k.keyword) > 5
ORDER BY 
    keyword_count DESC, actor_name ASC;
