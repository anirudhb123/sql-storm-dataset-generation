SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Distributor'
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
