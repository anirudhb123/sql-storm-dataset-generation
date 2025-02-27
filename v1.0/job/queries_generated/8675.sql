SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    c.nr_order AS role_order,
    y.info AS movie_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type,
    it.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info y ON t.id = y.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info_idx ii ON t.id = ii.movie_id
LEFT JOIN 
    info_type it ON ii.info_type_id = it.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
