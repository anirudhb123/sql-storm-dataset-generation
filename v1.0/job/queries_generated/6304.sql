SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    co.name AS company_name,
    ci.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(*) AS total_appearances
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info_idx mi ON t.id = mi.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
GROUP BY 
    a.name, t.title, c.kind, co.name, ci.info, k.keyword
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_appearances DESC, a.name;
