SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    tp.kind AS movie_type,
    cc.company_name AS company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    GROUP_CONCAT(DISTINCT pi.info) AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type tp ON t.kind_id = tp.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
AND 
    tp.kind IN ('Feature', 'Documentary')
GROUP BY 
    ak.name, t.title, tp.kind, cc.company_name
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    total_cast DESC, movie_title ASC;
