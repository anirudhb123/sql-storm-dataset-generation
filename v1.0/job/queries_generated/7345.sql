SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    c.role_id,
    COUNT(DISTINCT keyword.keyword) AS keyword_count,
    COUNT(DISTINCT ci.id) AS cast_info_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword ON mk.keyword_id = keyword.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mt.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, mt.title, mt.production_year, c.role_id
ORDER BY 
    keyword_count DESC, a.name ASC;
