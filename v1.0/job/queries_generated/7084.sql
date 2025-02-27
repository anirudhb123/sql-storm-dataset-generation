SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cc.name AS company_name,
    m.production_year AS production_year
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS cm ON mc.company_id = cm.id
WHERE 
    t.production_year >= 2000
    AND cm.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 50;
