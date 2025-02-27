
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.note AS casting_note,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE '%Smith%'
GROUP BY 
    t.title, a.name, r.role, c.note, t.production_year
ORDER BY 
    t.production_year DESC, t.title ASC
LIMIT 100;
