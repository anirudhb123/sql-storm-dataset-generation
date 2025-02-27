SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT pi.info, ', ') AS person_info
FROM 
    aka_title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    t.production_year > 2000
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography' OR info = 'Awards')
GROUP BY 
    t.title, a.name
ORDER BY 
    t.title ASC, actor_name DESC;
