SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS cast_type,
    GROUP_CONCAT(k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    MAX(m.production_year) AS latest_movie_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    aka_title at ON at.id = t.id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') AND 
    t.production_year > 2000
GROUP BY 
    t.title, a.name, p.info, c.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    latest_movie_year DESC;
