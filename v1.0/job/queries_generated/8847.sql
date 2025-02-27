SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    y.production_year, 
    COUNT(DISTINCT kw.keyword) AS total_keywords
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword kw ON mk.keyword_id = kw.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    role_type rt ON ci.person_role_id = rt.id 
JOIN 
    kind_type kt ON t.kind_id = kt.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND cn.country_code = 'USA' 
GROUP BY 
    a.name, t.title, c.kind, y.production_year 
ORDER BY 
    total_keywords DESC, 
    t.production_year ASC;
