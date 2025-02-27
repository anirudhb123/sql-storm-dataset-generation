SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT ci.person_role_id) AS roles_count
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
    movie_keyword mk ON ti.id = mk.movie_id
GROUP BY 
    ak.name, ti.title, ti.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    ti.production_year DESC, actor_name ASC
LIMIT 100;
