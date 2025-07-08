SELECT 
    m.title AS movie_title,
    p.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title m
JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
WHERE 
    m.production_year >= 2000
  AND 
    k.keyword LIKE '%action%'
ORDER BY 
    m.production_year DESC, 
    p.name ASC;
