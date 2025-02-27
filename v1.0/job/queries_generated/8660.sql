SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    DISTINCT COUNT(DISTINCT k.keyword) AS keyword_count,
    comp.name AS company_name,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND k.keyword ILIKE '%Drama%'
GROUP BY 
    a.name, t.title, c.note, comp.name, p.info
ORDER BY 
    keyword_count DESC, a.name, t.title;
