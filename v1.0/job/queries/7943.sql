
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS character_role,
    tc.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT cc.subject_id) AS complete_cast_count,
    COUNT(DISTINCT pi.info) AS person_info_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type tc ON mc.company_type_id = tc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND tc.kind LIKE '%studio%'
GROUP BY 
    a.name, t.title, c.role_id, tc.kind
ORDER BY 
    keywords DESC, complete_cast_count DESC, actor_name ASC;
