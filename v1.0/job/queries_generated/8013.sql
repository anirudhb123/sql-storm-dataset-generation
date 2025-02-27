SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id = it.id THEN LENGTH(mi.info) END) AS average_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000
    AND ct.kind LIKE '%Production%'
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    keyword_count > 5
ORDER BY 
    average_info_length DESC;
