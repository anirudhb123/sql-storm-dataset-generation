SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    mt.kind AS movie_kind,
    mi.info AS movie_info
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    person_info p ON c.person_id = p.person_id 
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
    kind_type mt ON t.kind_id = mt.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    a.name IS NOT NULL AND 
    t.production_year > 2000 AND 
    k.keyword ILIKE '%action%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
