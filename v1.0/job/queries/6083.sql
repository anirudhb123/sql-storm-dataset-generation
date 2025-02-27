
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
WHERE 
    a.person_id IN (SELECT person_id FROM person_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate') AND info IS NOT NULL)
AND 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT k.id) > 3
ORDER BY 
    t.production_year DESC, a.name;
