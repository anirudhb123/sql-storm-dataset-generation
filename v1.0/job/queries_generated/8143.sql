SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT pc.person_id) AS total_cast,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS average_movie_info,
    GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
    c.name AS company_name,
    COALESCE(SUM(m.movie_id), 0) AS total_movies
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    title mt ON ml.linked_movie_id = mt.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, ct.kind, k.keyword, c.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    total_cast DESC, movie_title;
