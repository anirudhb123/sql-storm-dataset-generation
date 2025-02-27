SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT c.person_role_id) AS roles_count,
    MAX(mi.info) AS movie_info,
    AVG(CAST(SUBSTRING(mi.info FROM '%[0-9]') AS INTEGER)) AS average_duration_minutes
FROM 
    title t
JOIN 
    aka_title at ON at.movie_id = t.id
JOIN 
    aka_name an ON an.id = at.id
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    name a ON a.id = c.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND k.keyword IS NOT NULL
GROUP BY 
    t.id, a.id
ORDER BY 
    roles_count DESC, average_duration_minutes DESC
LIMIT 100;

This query retrieves a list of movies produced between 2000 and 2022 along with their actors, associated keywords, count of roles played by each actor, and additional information. The results are grouped by movie and actor, sorted by the count of roles and average duration.
