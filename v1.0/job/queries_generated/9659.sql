SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
    COUNT(DISTINCT ci.person_role_id) AS total_roles
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mw ON ti.id = mw.movie_id
JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    ti.production_year > 2000
GROUP BY 
    ak.name, ti.title, ti.production_year
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 1
ORDER BY 
    ti.production_year DESC, actor_name ASC;
