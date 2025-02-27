SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    COUNT(DISTINCT m.id) AS total_movies,
    MAX(t.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    total_movies DESC, latest_movie_year DESC;
