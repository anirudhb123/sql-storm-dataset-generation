SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT c.note) AS cast_notes,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c2.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT pi.info) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 1990 AND 2023
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.id, t.id, c2.id, ct.id
ORDER BY 
    COUNT(DISTINCT k.id) DESC, a.name ASC;
