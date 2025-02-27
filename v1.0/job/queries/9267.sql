
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT pi.info, ', ') AS additional_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000
    AND ct.kind LIKE 'Production%'
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    a.name, t.title;
