SELECT 
    COUNT(DISTINCT n.id) AS unique_names,
    AVG(mi.info_length) AS avg_info_length,
    ct.kind AS company_type,
    kay.title AS movie_title,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_cast
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    title kay ON mc.movie_id = kay.id
JOIN 
    movie_info mi ON kay.id = mi.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    ct.kind LIKE '%Production%'
GROUP BY 
    ct.kind, kay.title
HAVING 
    COUNT(DISTINCT an.id) > 10
ORDER BY 
    avg_info_length DESC;
