SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    co.name AS company_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, c.kind, co.name
ORDER BY 
    keyword_count DESC, avg_info_length DESC;
