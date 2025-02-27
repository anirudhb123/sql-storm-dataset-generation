SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS role_note,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT pi.info ORDER BY pi.info_type_id SEPARATOR '; ') AS person_info,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT kw.id) AS keyword_count
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS pi ON a.id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    t.id, a.id, ci.note, c.kind
ORDER BY 
    COUNT(DISTINCT kw.id) DESC, 
    movie_title ASC;
