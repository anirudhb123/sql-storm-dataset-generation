SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.kind AS cast_type,
    ci.name AS company_name,
    COUNT(DISTINCT ci.id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, k.keyword, c.kind, ci.name
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    company_count DESC, actor_name;
