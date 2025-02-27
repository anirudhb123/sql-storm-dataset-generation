
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    pi.info AS director_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    ci.nr_order = 1
GROUP BY 
    a.name, t.title, t.production_year, pi.info
ORDER BY 
    t.production_year DESC, a.name;
