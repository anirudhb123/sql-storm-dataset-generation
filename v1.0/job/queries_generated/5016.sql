SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name) AS company_names,
    r.role AS role_type,
    p.info AS person_info,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name c ON c.id = (
        SELECT mc.company_id 
        FROM movie_companies mc 
        WHERE mc.movie_id = t.id 
        LIMIT 1
    )
JOIN 
    company_type ct ON c.id = ct.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND r.role IS NOT NULL
GROUP BY 
    a.id, t.id, r.id, p.info
ORDER BY 
    total_movies DESC, actor_name;
