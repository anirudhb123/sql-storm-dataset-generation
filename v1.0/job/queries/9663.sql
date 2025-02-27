
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(*) AS number_of_actors
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
WHERE 
    t.production_year >= 2000
    AND ct.kind LIKE '%Production%'
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    number_of_actors DESC, t.title ASC
LIMIT 10;
