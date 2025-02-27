SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT pi.id) AS person_info_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000 
    AND co.country_code = 'USA'
    AND c.nr_order < 3
GROUP BY 
    a.id, a.name, t.title, c.note, co.name
ORDER BY 
    keyword_count DESC, t.title ASC
LIMIT 100;
