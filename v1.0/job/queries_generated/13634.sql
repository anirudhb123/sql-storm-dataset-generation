SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    mp.note AS movie_note
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, ak.name;
