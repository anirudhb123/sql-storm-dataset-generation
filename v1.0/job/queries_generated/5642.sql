SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.gender, 
    k.keyword AS movie_keyword, 
    ci.kind AS company_type, 
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON c.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    movie_info mi ON t.id = mi.movie_id AND it.id = mi.info_type_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND k.keyword IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC 
LIMIT 100;
