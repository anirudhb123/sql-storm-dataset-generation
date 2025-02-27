SELECT 
    t.title AS movie_title,
    c.name AS cast_member,
    rt.role AS role,
    co.name AS company_name,
    mt.kind AS company_type,
    COUNT(mk.keyword) AS keyword_count,
    COUNT(DISTINCT pi.info) AS info_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    person_info pi ON an.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, c.name, rt.role, co.name, mt.kind
ORDER BY 
    keyword_count DESC, movie_title ASC;
