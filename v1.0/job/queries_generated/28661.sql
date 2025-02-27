SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS actor_role,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(k.keyword, ', ') AS keywords_list,
    COALESCE(n.info, 'No additional info') AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id 
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info n ON a.person_id = n.person_id AND n.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    m.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND LENGTH(a.name) > 5 
GROUP BY 
    a.name, m.title, m.production_year, r.role, n.info 
ORDER BY 
    keyword_count DESC, actor_name ASC;
