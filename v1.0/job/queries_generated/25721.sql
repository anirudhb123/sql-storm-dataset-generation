SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
    pi.info AS person_info,
    mi.info AS movie_info,
    COUNT(DISTINCT c.movie_id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, pi.info, mi.info
ORDER BY 
    total_movies DESC, a.name;
