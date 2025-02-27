SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    GROUP_CONCAT(DISTINCT d.info) AS director_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info = 'director'
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.role_id
ORDER BY 
    t.production_year DESC, a.name;
