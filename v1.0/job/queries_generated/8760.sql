SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT m.id) AS related_movies,
    SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS modern_movies_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND k.keyword IS NOT NULL 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
GROUP BY 
    a.name, t.title, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    modern_movies_count DESC, actor_name ASC;
