SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.role_id AS role_id,
    cc.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS m ON c.movie_id = m.id
JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS cc ON mc.company_type_id = cc.id
JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id 
WHERE 
    m.production_year BETWEEN 2000 AND 2023
AND 
    cc.kind LIKE 'Production%'
ORDER BY 
    a.name, m.title;
