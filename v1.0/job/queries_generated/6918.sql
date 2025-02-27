SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    cname.name AS company_name,
    COUNT(ki.keyword) AS keyword_count,
    MIN(mi.production_year) AS earliest_production_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cname ON mc.company_id = cname.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND cname.country_code = 'USA'
GROUP BY 
    t.title, a.name, ct.kind, cname.name
HAVING 
    COUNT(ki.keyword) > 5
ORDER BY 
    earliest_production_year DESC, movie_title;
