SELECT 
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    a.name AS actor_name,
    pi.info AS person_info,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT ca.person_id) AS actor_count
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ca ON cc.subject_id = ca.id
JOIN 
    aka_name a ON ca.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
AND 
    k.keyword LIKE 'action%'
AND 
    pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    t.title, k.keyword, c.kind, a.name, pi.info
ORDER BY 
    movie_title, actor_name;
