SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    pi.info AS person_info,
    ki.keyword AS movie_keyword
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    c.kind LIKE '%Production%'
ORDER BY 
    t.title, a.name;
