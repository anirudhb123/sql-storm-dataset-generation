SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    COUNT(DISTINCT pi.info) AS total_personal_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON ci.movie_id = t.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    t.id, a.id, cn.name
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    total_movies DESC, 
    movie_title ASC;
