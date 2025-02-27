SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_name,
    cc.kind AS company_type,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, a.name, c.nr_order;
