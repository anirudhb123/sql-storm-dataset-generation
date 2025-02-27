SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.note AS cast_note,
    c.nr_order AS cast_order,
    mci.info AS movie_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    i.info AS info_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
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
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND r.role IN ('Actor', 'Director')
    AND k.keyword LIKE '%Drama%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
