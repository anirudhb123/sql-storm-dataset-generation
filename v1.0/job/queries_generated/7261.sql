SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword, 
    COUNT(DISTINCT pc.person_id) AS cast_count,
    STRING_AGG(DISTINCT CONCAT(pi.info_type_id, ': ', pi.info), '; ') AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, k.keyword
ORDER BY 
    cast_count DESC, movie_title ASC;
