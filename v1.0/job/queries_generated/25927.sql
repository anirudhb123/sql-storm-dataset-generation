SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT co.id) AS company_count,
    SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS modern_movies_count,
    GROUP_CONCAT(DISTINCT pi.info) AS person_info_details
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    modern_movies_count DESC, company_count ASC;
