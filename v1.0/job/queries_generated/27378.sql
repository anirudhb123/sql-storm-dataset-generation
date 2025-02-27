SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    k.keyword AS movie_keyword,
    p.info AS actor_info,
    rt.role AS actor_role,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year >= 1990
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.id, m.id, k.id, p.id, rt.id
ORDER BY 
    m.production_year DESC, a.name;
