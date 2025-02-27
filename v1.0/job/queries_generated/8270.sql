SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    co.name AS company_name,
    p.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    person_info p ON c.id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.id, c.id, co.id, p.id
ORDER BY 
    t.production_year DESC, c.name ASC;
