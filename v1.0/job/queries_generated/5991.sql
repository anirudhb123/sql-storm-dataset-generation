SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    COUNT(DISTINCT cc.subject_id) AS total_cast,
    COUNT(DISTINCT mci.company_id) AS total_companies
FROM 
    aka_title at
JOIN 
    title t ON at.movie_id = t.id
JOIN 
    cast_info cc ON t.id = cc.movie_id
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    movie_companies mci ON t.id = mci.movie_id
JOIN 
    company_type c ON mci.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ak.name IS NOT NULL 
    AND c.kind IS NOT NULL 
GROUP BY 
    ak.name, t.title, p.name, c.kind, k.keyword, mi.info
ORDER BY 
    total_cast DESC, total_companies DESC
LIMIT 100;
