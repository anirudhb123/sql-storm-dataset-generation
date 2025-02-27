SELECT 
    tn.title AS movie_title,
    ak.name AS actor_name,
    rp.role AS role_type,
    ci.nr_order AS role_order,
    m.production_year,
    cn.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    title tn
JOIN 
    complete_cast cc ON tn.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rp ON ci.role_id = rp.id
JOIN 
    movie_companies mc ON tn.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON tn.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    tn.production_year >= 2000
ORDER BY 
    tn.production_year DESC, 
    ak.name;
