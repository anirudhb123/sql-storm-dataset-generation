SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    c.kind AS company_type,
    t.kind AS title_kind,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = mt.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    title t ON t.id = mt.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    mt.production_year > 2000
    AND c.kind = 'Production'
ORDER BY 
    mt.production_year DESC,
    a.name;
