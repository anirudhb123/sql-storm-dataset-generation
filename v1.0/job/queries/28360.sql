
SELECT 
    akn.name AS aka_name,
    t.title AS movie_title,
    p.gender,
    COUNT(DISTINCT cc.id) AS total_cast_members,
    STRING_AGG(DISTINCT p_info.info, '; ') AS person_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    aka_name akn
JOIN 
    cast_info cc ON akn.person_id = cc.person_id
JOIN 
    title t ON cc.movie_id = t.id
JOIN 
    name p ON akn.person_id = p.imdb_id
LEFT JOIN 
    person_info p_info ON p.id = p_info.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    akn.name LIKE '%Smith%'
    AND t.production_year >= 2000
GROUP BY 
    akn.name, t.title, p.gender
ORDER BY 
    total_cast_members DESC;
