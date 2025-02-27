SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    ci.note AS role_note,
    c.name AS company_name,
    kt.keyword AS movie_keyword,
    mi.info AS movie_info,
    p.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    kind_type ktp ON t.kind_id = ktp.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, a.name;
