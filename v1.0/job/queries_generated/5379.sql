SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    ct.kind AS company_type, 
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords, 
    COUNT(mi.id) AS info_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name IS NOT NULL
AND 
    ct.kind IS NOT NULL
GROUP BY 
    t.id, a.name, ct.kind
ORDER BY 
    COUNT(mi.id) DESC, t.title ASC
LIMIT 10;
