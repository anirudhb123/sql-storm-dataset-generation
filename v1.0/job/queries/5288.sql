
SELECT 
    a.person_id,
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(DISTINCT rr.role_id) AS total_roles,
    AVG(mi.info_length) AS avg_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    (SELECT 
         movie_id,
         AVG(LENGTH(info)) AS info_length
     FROM 
         movie_info 
     GROUP BY 
         movie_id) mi ON t.id = mi.movie_id
JOIN 
    (SELECT 
         ci2.role_id, 
         ci2.movie_id 
     FROM 
         cast_info ci2 
     GROUP BY 
         ci2.role_id, ci2.movie_id) rr ON ci.role_id = rr.role_id AND ci.movie_id = rr.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.person_id, a.name, t.title, ct.kind, mi.info_length
ORDER BY 
    total_roles DESC, avg_info_length DESC
LIMIT 100;
