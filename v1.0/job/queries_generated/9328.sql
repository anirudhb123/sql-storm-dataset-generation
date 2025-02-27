SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ci.kind AS cast_type,
    AVG(m.production_year) AS avg_production_year,
    COUNT(DISTINCT pc.person_id) AS total_cast_count
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
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info pi ON a.id = pi.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
    AND mk.keyword LIKE '%Action%'
GROUP BY 
    t.title, a.name, ci.kind
HAVING 
    AVG(m.production_year) > 2010
ORDER BY 
    keyword_count DESC, movie_title;
