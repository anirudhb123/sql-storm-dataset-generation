-- Performance Benchmarking SQL Query
SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    GROUP_CONCAT(key.keyword) AS keywords,
    c.company_name AS production_company,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword key ON mk.keyword_id = key.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, ak.name, c.company_name, mi.info
ORDER BY 
    t.title;
