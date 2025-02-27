SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    ct.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, ct.kind
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    keyword_count DESC, 
    movie_title ASC;
