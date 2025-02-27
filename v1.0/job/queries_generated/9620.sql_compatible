
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    mk.keyword AS movie_keyword,
    COUNT(DISTINCT c.note) AS total_cast_notes,
    COUNT(DISTINCT pi.info) AS total_person_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword mk ON mk.id IN (SELECT movie_keyword.keyword_id FROM movie_keyword WHERE movie_keyword.movie_id = t.id)
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
GROUP BY 
    a.name, t.title, ct.kind, mk.keyword
ORDER BY 
    total_cast_notes DESC, a.name ASC;
