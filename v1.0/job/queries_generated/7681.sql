SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT c.id) AS total_companies,
    COUNT(DISTINCT m.id) AS total_infos,
    COUNT(DISTINCT mk.id) AS total_movie_keywords
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    keyword k ON t.id = k.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
GROUP BY 
    t.id, a.name, c.kind, m.info, k.keyword
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    t.production_year DESC, movie_title;
