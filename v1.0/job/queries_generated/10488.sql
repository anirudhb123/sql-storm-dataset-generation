SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS role,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    info.info AS movie_info
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS comp ON mc.company_id = comp.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS info ON t.id = info.movie_id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title, a.name;
