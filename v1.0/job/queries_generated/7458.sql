SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    ci.info AS company_info,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    k.keyword LIKE '%action%'
AND 
    ct.kind = 'Producer'
ORDER BY 
    t.production_year DESC, 
    a.name;
