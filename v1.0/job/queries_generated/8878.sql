SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.keyword_id) AS keyword_count,
    AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) END) AS avg_bio_length,
    COUNT(DISTINCT pi.id) AS total_info_entries
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword m ON mk.keyword_id = m.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, avg_bio_length DESC;
