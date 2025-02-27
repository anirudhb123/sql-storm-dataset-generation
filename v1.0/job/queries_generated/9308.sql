SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_kind,
    p.info AS person_info,
    m.keywords
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND ci.nr_order = 1
    AND cc.status_id = 1
ORDER BY 
    t.title, ak.name;
