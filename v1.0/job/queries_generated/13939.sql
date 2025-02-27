SELECT 
    a.title,
    p.name AS person_name,
    c.kind AS company_name,
    m.production_year,
    k.keyword
FROM 
    aka_title a
JOIN 
    complete_cast cc ON a.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_companies mc ON a.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON a.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title t ON a.id = t.id
JOIN 
    person_info pi ON an.id = pi.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    a.title, p.name;
