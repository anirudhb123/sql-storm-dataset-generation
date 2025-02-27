SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    k.keyword AS movie_keyword,
    pt.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year >= 2000 
    AND ci.nr_order < 5 
    AND ct.kind ILIKE '%Production%'
ORDER BY 
    t.production_year DESC, 
    a.name;
