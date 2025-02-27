SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    r.role AS role_title,
    c.note AS cast_note,
    ci.kind AS comp_cast_type,
    c2.name AS company_name,
    m.production_year AS movie_year,
    ki.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.note IS NOT NULL
    AND ci.kind IS NOT NULL
ORDER BY 
    t.production_year DESC, ak.name, movie_title;
