
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(DISTINCT c.id) AS total_cast,
    COUNT(DISTINCT k.keyword) AS total_keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND ct.kind IN ('Production', 'Distribution')
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    total_cast DESC, total_keywords DESC
LIMIT 50;
