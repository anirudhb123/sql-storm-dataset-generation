
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    cg.kind AS company_kind,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    LENGTH(t.title) AS title_length,
    AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS avg_person_info_present
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS cg ON mc.company_type_id = cg.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, cg.kind, t.id, a.person_id
ORDER BY 
    keyword_count DESC, title_length ASC
LIMIT 
    100;
