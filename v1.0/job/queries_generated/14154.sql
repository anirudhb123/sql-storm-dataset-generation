SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_kind,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
ORDER BY 
    t.title, a.name;
