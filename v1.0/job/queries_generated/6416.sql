SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    ci.nr_order AS cast_order,
    pi.info AS actor_info
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON an.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    an.name ASC;
