
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT mi.id) AS info_count
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year > 2000 
    AND c.kind IS NOT NULL 
GROUP BY 
    a.name, t.title, c.kind 
ORDER BY 
    info_count DESC, actor_name ASC;
