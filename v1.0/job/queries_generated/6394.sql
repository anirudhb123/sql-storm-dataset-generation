SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS person_info,
    c.kind AS role_kind,
    k.keyword AS movie_keyword,
    COUNT(m.id) AS num_movies
FROM 
    aka_title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    kind_type AS kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000 AND 
    cn.country_code = 'USA' AND 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
GROUP BY 
    t.title, a.name, p.info, c.kind, k.keyword
HAVING 
    COUNT(m.id) > 3
ORDER BY 
    num_movies DESC;
