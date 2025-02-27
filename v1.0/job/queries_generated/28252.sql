SELECT 
    title.title AS movie_title,
    aka_name.name AS actor_name,
    COUNT(DISTINCT movie_info.info) AS info_count,
    GROUP_CONCAT(DISTINCT keyword.keyword) AS keywords,
    AVG(CASE WHEN title.production_year IS NOT NULL THEN title.production_year ELSE NULL END) AS avg_production_year
FROM 
    title
JOIN 
    movie_info ON title.id = movie_info.movie_id
JOIN 
    movie_keyword ON title.id = movie_keyword.movie_id
JOIN 
    keyword ON movie_keyword.keyword_id = keyword.id
JOIN 
    cast_info ON title.id = cast_info.movie_id
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
LEFT JOIN 
    person_info ON aka_name.person_id = person_info.person_id AND person_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Birth Year')
WHERE 
    title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
AND 
    title.production_year >= 2000
GROUP BY 
    title.id, aka_name.name
HAVING 
    COUNT(DISTINCT movie_info.info) > 2
ORDER BY 
    avg_production_year DESC, movie_title ASC;
