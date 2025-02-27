SELECT 
    t.title,
    a.name AS actor_name,
    a.id AS actor_id,
    tc.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id 
JOIN 
    role_type r ON cc.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ct.kind = 'Production'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')
ORDER BY 
    t.production_year DESC, a.name ASC;
