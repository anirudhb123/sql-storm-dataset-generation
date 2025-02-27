SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    k.keyword AS movie_keyword,
    c.kind AS comp_cast_type,
    cp.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC;
