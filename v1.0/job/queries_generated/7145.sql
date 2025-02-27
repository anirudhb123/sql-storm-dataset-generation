SELECT 
    ak.name AS actor_name, 
    ti.title AS movie_title, 
    ti.production_year, 
    GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS companies_involved,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
    COUNT(DISTINCT c.role_id) AS roles_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title ti ON c.movie_id = ti.id
LEFT JOIN 
    movie_companies mc ON ti.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mw ON ti.id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    ti.production_year >= 2000
GROUP BY 
    ak.name, ti.title, ti.production_year
HAVING 
    COUNT(DISTINCT c.role_id) > 1
ORDER BY 
    ti.production_year DESC, actor_name;
