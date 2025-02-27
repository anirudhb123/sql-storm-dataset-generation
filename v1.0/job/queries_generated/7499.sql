SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(mk.id) AS keyword_count,
    ci.role_id AS role,
    cc.kind AS company_type,
    m.production_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    t.id, a.name, ci.role_id, cc.kind, m.production_year
ORDER BY 
    keyword_count DESC, t.title;
