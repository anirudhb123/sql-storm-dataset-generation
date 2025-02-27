SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    cc.subject_id AS complete_cast_subject,
    mi.info AS movie_information
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND c.kind LIKE '%Production%'
    AND ak.name LIKE '%Smith%'
ORDER BY 
    t.production_year DESC, ak.name ASC;
