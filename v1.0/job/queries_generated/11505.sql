SELECT 
    t.title AS movie_title,
    ak.name AS aka_name,
    ci.note AS cast_note,
    cn.name AS company_name,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, ak.name;
