SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    MIN(mi.info) AS first_info,
    MAX(mi.info) AS last_info
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    aka_title t ON ca.movie_id = t.movie_id
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
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    total_keywords DESC, actor_name ASC, movie_title ASC
LIMIT 100;
