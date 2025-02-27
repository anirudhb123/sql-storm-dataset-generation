SELECT 
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    a.name AS actor_name,
    p.info AS actor_info,
    ci.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(CASE WHEN ci.kind = 'Production' THEN mc.note END) AS average_production_notes
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    person_info p ON c.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword IS NOT NULL
GROUP BY 
    t.title, k.keyword, a.name, p.info, ci.kind
ORDER BY 
    total_companies DESC, cast_count DESC;
