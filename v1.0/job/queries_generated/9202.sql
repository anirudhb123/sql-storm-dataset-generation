SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    pc.info AS person_info,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    ci.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pc ON a.person_id = pc.person_id
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
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL 
    AND pc.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, a.name;
