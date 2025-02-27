SELECT 
    a.name AS actor_name,
    a.imdb_index AS actor_index,
    t.title AS movie_title,
    t.production_year AS release_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    LENGTH(a.name) AS actor_name_length,
    LENGTH(t.title) AS movie_title_length,
    COUNT(DISTINCT c.id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT k.id) > 0
ORDER BY 
    actor_name_length DESC, 
    movie_title_length ASC;
