SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name ILIKE '%Smith%'
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name;

This query retrieves data about actors named "Smith" who have worked in movies from 2000 to 2020. It includes the actor's name, movie title, production year, their character's role, and the companies involved in the movie production along with keywords associated with each movie. The results are grouped by actor name, movie title, year, and role, and ordered by production year and actor name. The use of `GROUP_CONCAT` aggregates company names and keywords associated with each movie. The `ILIKE` function is used for case-insensitive matching.
