
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(ci.person_id) AS total_cast,
    AVG(CAST(mi.info AS numeric)) AS avg_movie_rating
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
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND c.kind = 'Production'
GROUP BY 
    a.name, t.title, c.kind, mi.info
HAVING 
    COUNT(ci.person_id) > 3
ORDER BY 
    avg_movie_rating DESC, total_cast DESC
LIMIT 10;
