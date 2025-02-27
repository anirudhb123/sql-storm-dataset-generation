SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_biography,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    m.production_year,
    COUNT(DISTINCT cc.person_id) AS total_actors
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c_info ON at.id = c_info.movie_id
JOIN 
    aka_name a ON c_info.person_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
GROUP BY 
    t.title, a.name, p.info, m.production_year
ORDER BY 
    m.production_year DESC, total_actors DESC
LIMIT 50;
