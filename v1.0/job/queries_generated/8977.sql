SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    c.role_id AS role_id,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
    COALESCE(MAX(mi.info), 'No additional info') AS info
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    p.name, m.title, c.role_id, m.production_year
ORDER BY 
    m.production_year DESC, actor_name;
