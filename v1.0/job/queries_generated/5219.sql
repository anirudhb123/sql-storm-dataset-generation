SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.keyword_id) AS keyword_count,
    MAX(mi.info) AS movie_note
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
JOIN 
    movie_keyword m ON t.id = m.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.keyword_id) > 3
ORDER BY 
    keyword_count DESC, movie_title ASC;
