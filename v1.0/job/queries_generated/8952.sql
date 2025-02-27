SELECT 
    a.name as actor_name,
    t.title as movie_title,
    c.kind as company_type,
    ki.keyword as movie_keyword,
    p.info as person_info,
    COUNT(co.id) as total_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND c.kind = 'Production'
GROUP BY 
    a.name, t.title, c.kind, ki.keyword, p.info
ORDER BY 
    total_companies DESC, a.name ASC;
