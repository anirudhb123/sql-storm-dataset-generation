SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    COUNT(DISTINCT ci.id) AS num_of_companies,
    COUNT(DISTINCT mi.id) AS num_of_movie_info
FROM 
    aka_name p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    char_name c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type co ON mc.company_type_id = co.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND k.keyword IS NOT NULL
GROUP BY 
    p.id, t.id, c.id, k.id, ci.kind
ORDER BY 
    num_of_companies DESC, num_of_movie_info DESC;
