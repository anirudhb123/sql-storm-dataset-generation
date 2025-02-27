SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS num_production_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    t.production_year DESC, a.name;

This query benchmarks string processing by retrieving distinct actors and their associated movie titles, production years, and role types, while also aggregating keywords and counting the number of production companies involved. The results are filtered to only include movies with more than one production company. The final output is ordered by the production year in descending order and by actor name.
