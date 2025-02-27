SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id,
    ct.kind AS company_type,
    inf.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type inf ON mi.info_type_id = inf.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND ak.name IS NOT NULL 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
