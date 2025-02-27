SELECT 
    t.title AS movie_title,
    cn.name AS company_name,
    an.name AS actor_name,
    ct.kind AS company_type,
    mw.keyword AS movie_keyword,
    ti.info AS additional_info
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name an ON cc.subject_id = an.person_id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    person_info pi ON an.person_id = pi.person_id
JOIN 
    info_type ti ON pi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
