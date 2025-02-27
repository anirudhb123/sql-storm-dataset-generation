SELECT 
    m.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    k.keyword AS keyword,
    ci.info AS movie_info
FROM 
    title m
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    cast_info ci ON m.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
