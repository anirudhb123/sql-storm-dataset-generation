SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_kind,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT mcn.name) AS production_companies,
    MAX(mi.info) AS movie_info,
    COUNT(DISTINCT r.id) AS total_cast
FROM 
    title AS t
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS mcn ON mc.company_id = mcn.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND r.role IN ('Actor', 'Director')
GROUP BY 
    t.id, a.id, c.kind
ORDER BY 
    keyword_count DESC, movie_title ASC;
