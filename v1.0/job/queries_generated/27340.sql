SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT g.keyword ORDER BY g.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
    ti.info AS movie_info,
    COUNT(DISTINCT c.id) AS cast_count
FROM 
    title t
JOIN 
    aka_title at ON at.movie_id = t.id
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword g ON g.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN 
    info_type ti ON ti.id = mi.info_type_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND t.title IS NOT NULL
GROUP BY 
    t.id, a.name, ti.info
ORDER BY 
    CAST_COUNT DESC, movie_title ASC;
