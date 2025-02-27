SELECT 
    a.name AS actor_name, 
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    AVG(CASE WHEN m.production_year BETWEEN 2000 AND 2020 THEN 1 ELSE 0 END) AS avg_movies_2000s,
    COUNT(DISTINCT CASE WHEN m.production_year < 2000 THEN m.id END) AS pre_2000_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year IS NOT NULL
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%plot%')
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT ci.role_id) > 2 
ORDER BY 
    total_companies DESC, 
    avg_movies_2000s DESC;
