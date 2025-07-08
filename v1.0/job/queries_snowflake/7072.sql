
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role,
    cc.kind AS casting_type,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info,
    COUNT(DISTINCT a.id) AS actor_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, c.role_id, cc.kind, m.name, k.keyword, i.info, t.production_year
ORDER BY 
    actor_count DESC, t.production_year DESC;
