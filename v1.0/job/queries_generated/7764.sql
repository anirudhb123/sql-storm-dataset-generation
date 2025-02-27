SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(mi.info_length) AS avg_info_length
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
GROUP BY 
    t.title, a.name, p.info, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 5 AND AVG(mi.info_length) < 100
ORDER BY 
    keyword_count DESC, avg_info_length ASC;
