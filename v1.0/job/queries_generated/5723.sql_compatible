
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    p.info AS person_info,
    COUNT(DISTINCT mc.company_id) AS company_count
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
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, c.kind, p.info
ORDER BY 
    company_count DESC, a.name;
