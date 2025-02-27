SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword ASC) AS keywords,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name ASC) AS companies,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND kw.keyword IS NOT NULL
GROUP BY 
    t.id, a.id
ORDER BY 
    COUNT(DISTINCT kw.id) DESC, t.title ASC;
