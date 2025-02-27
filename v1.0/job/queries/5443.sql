SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    ci.note AS casting_note,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order < 5
    AND ct.kind LIKE 'Production%'
ORDER BY 
    t.production_year DESC, 
    ak.name;
