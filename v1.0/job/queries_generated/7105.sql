SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS actor_role, 
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(COALESCE(mi.info::integer, 0)) AS avg_movie_info_value
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
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
JOIN 
    role_type r ON ci.role_id = r.id
GROUP BY 
    t.title, a.name, r.role, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT mc.id) > 1 
ORDER BY 
    total_movies DESC, avg_movie_info_value DESC
LIMIT 50;
