SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    ki.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT ci.role_id) AS roles,
    COUNT(DISTINCT p.id) AS num_persons,
    COUNT(DISTINCT mi.info) AS num_movie_infos
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    num_movie_infos DESC, actor_name ASC
LIMIT 100;
