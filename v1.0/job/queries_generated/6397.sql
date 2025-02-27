SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS personal_info,
    k.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    COUNT(DISTINCT mc.movie_id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000 AND 
    a.name IS NOT NULL 
GROUP BY 
    a.name, t.title, c.kind, p.info, k.keyword
ORDER BY 
    total_movies DESC, actor_name ASC;
