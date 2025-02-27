SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_role,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(mi.info) AS average_movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND c.kind = 'Distributor'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    total_cast DESC, average_movie_info DESC
LIMIT 10;
