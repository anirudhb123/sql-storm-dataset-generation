SELECT 
    m.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    c.country_code AS production_country,
    COUNT(DISTINCT mi.info) AS info_count
FROM 
    aka_title AS m
JOIN 
    cast_info AS ci ON m.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.person_role_id = r.id
JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_info AS mi ON m.id = mi.movie_id
WHERE 
    m.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    m.title, a.name, r.role, k.keyword, c.country_code
ORDER BY 
    movie_title ASC, actor_name ASC;
