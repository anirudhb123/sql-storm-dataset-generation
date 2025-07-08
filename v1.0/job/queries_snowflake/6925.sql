SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ci.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000
    AND a.name LIKE '%Smith%'
    AND k.keyword IN ('Action', 'Adventure')
ORDER BY 
    t.production_year DESC, a.name ASC;
