SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info,
    COUNT(DISTINCT ca.person_id) AS total_actors,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ca ON cc.id = ca.movie_id
JOIN 
    aka_name a ON ca.person_id = a.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind, k.keyword, i.info
ORDER BY 
    total_movies DESC, total_actors DESC;
