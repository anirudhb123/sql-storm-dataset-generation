SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS cast_type, 
    COUNT(k.keyword) AS keyword_count, 
    COUNT(DISTINCT co.name) AS company_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name ILIKE '%Smith%'
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    keyword_count DESC, movie_title ASC;
