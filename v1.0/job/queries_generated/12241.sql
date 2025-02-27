SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mr.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword mr ON mk.keyword_id = mr.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, ak.name;
