SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS company_type, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword 
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
