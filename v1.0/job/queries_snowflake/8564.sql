SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ki.kind AS movie_kind,
    c.country_code AS company_country,
    mi.info AS movie_info,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
JOIN 
    aka_name ak ON ca.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    kind_type ki ON t.kind_id = ki.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, ak.name, ki.kind, c.country_code, mi.info
ORDER BY 
    movie_title ASC, actor_name ASC;
