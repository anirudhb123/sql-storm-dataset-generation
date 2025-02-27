SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    pi.info AS actor_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON c.id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id 
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind, m.production_year, pi.info
ORDER BY 
    t.production_year DESC, COUNT(DISTINCT mc.company_id) DESC;
