SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    p.gender AS person_gender, 
    cc.kind AS cast_type, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    COUNT(mc.movie_id) AS total_movies,
    COUNT(DISTINCT r.role) AS distinct_roles
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
GROUP BY 
    ak.name, t.title, p.gender, cc.kind
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC, aka_name ASC;
