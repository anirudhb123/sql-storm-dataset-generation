SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    com.name AS company_name,
    ct.kind AS company_type,
    it.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    info_type it ON p.info_type_id = it.id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name;
