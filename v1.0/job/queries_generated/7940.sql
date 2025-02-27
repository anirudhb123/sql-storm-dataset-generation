SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS company_kind, 
    kc.keyword AS movie_keyword, 
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info csi ON cc.subject_id = csi.id
JOIN 
    aka_name a ON csi.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000 
    AND c.kind = 'Distributor'
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
ORDER BY 
    t.production_year DESC, 
    a.name;
