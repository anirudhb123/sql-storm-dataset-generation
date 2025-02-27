SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ckt.kind AS cast_type,
    cinfo.info AS movie_info,
    cpn.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type ckt ON ci.person_role_id = ckt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cpn ON mc.company_id = cpn.id
WHERE 
    t.production_year > 2000
    AND ak.name IS NOT NULL
    AND ckt.kind = 'actor'
ORDER BY 
    t.production_year DESC, t.title, ak.name;
