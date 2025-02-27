SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    ti.info AS movie_info,
    COUNT(*) AS total_movies
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
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
GROUP BY 
    a.name, t.title, c.kind, k.keyword, p.info, ti.info
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_movies DESC;
