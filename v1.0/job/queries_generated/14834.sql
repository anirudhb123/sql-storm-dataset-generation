SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 1990 AND 2000
ORDER BY 
    t.title, ak.name;
