SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_bio,
    c.kind AS company_type,
    count(mk.keyword) AS keyword_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    person_info p ON p.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON c.id = mc.company_type_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    ci.nr_order = 1
GROUP BY 
    t.id, a.id, p.id, c.id
ORDER BY 
    keyword_count DESC, movie_title ASC;
