SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    ti.info AS movie_info,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, t.title, c.kind, ti.info
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    keyword_count DESC;
