SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    ci.nr_order AS cast_order,
    pi.info AS person_info,
    kt.keyword AS movie_keyword
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
    person_info pi ON ci.person_id = pi.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND kt.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    ci.nr_order;
