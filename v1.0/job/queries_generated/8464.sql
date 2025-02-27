SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MIN(mi.info) AS min_movie_info,
    MAX(mi.info) AS max_movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND co.country_code IN ('USA', 'UK', 'CAN')
    AND rt.role = 'Actor'
GROUP BY 
    a.name, t.title, c.kind, co.name
ORDER BY 
    keyword_count DESC, actor_name ASC;
