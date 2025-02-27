SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS companies,
    GROUP_CONCAT(DISTINCT pi.info) AS person_info
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS rt ON ci.role_id = rt.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
JOIN 
    info_type AS it ON pi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
AND 
    rt.role = 'actor'
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    t.title, a.name;
