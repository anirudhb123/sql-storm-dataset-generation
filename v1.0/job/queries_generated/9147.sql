SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_type, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mi.info) AS average_movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND ct.kind = 'Production'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    actor_name, movie_title;
