SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
    GROUP_CONCAT(DISTINCT p.info) AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
    AND kt.kind = 'movie'
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 3
ORDER BY 
    actor_name ASC, movie_title ASC;
