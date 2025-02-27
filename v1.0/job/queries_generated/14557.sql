SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k2 ON mk.keyword_id = k2.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
