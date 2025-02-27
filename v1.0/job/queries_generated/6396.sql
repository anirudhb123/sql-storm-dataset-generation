SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS comp_cast_type,
    ci.name AS company_name,
    mi.info AS movie_info,
    m.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name ci ON mc.company_id = ci.id 
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
WHERE 
    t.production_year >= 2000 
    AND ci.country_code = 'USA' 
GROUP BY 
    t.title, a.name, ct.kind, ci.name, mi.info, m.production_year 
ORDER BY 
    keyword_count DESC, t.title
LIMIT 50;
