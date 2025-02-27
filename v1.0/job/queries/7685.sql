SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.id) AS movie_count,
    SUM(CASE WHEN m.production_year = 2023 THEN 1 ELSE 0 END) AS recent_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON ci.movie_id = m.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.id) > 1 
ORDER BY 
    movie_count DESC, actor_name ASC;
