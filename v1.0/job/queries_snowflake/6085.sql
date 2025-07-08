
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_kind,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id = it.id THEN LENGTH(mi.info) END) AS avg_info_length
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
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.name, t.title, ct.kind, it.id
HAVING 
    COUNT(DISTINCT kw.keyword) > 5
ORDER BY 
    avg_info_length DESC;
