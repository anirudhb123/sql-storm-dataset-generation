SELECT 
    ak.name AS aka_name,
    m.title AS movie_title,
    c.role_id AS role_type_id,
    r.role AS role_description,
    COUNT(*) AS total_appearances,
    COALESCE(NULLIF(EXTRACT(YEAR FROM MAX(m.production_year)), 0), 'Unknown Year') AS last_movie_year,
    COUNT(DISTINCT m.info_type_id) AS unique_info_types
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    ak.name ILIKE '%Smith%' 
    AND m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, m.title, c.role_id, r.role
ORDER BY 
    total_appearances DESC, last_movie_year DESC
LIMIT 
    50;
