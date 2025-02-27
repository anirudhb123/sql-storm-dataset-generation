SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.keyword_id) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_movie_length,
    SUM(CASE WHEN pi.info_type_id = 2 THEN 1 ELSE 0 END) AS total_actor_awards
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
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword m ON mk.keyword_id = m.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.keyword_id) > 5
ORDER BY 
    avg_movie_length DESC;
