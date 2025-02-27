SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    ct.kind = 'Distributor'
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    p.name ASC;
