SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS year_of_production,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
    rc.role AS role,
    COUNT(mi.id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type rc ON ci.role_id = rc.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.name, t.title, t.production_year, rc.role
ORDER BY 
    t.production_year DESC, COUNT(mi.id) DESC;

This SQL query retrieves a comprehensive overview of actors and the movies they've participated in since the year 2000, specifically focusing on those classified as movies. It aggregates the information, including associated keywords, roles, and the count of associated information entries for each movie. The results are displayed in descending order by the production year and the count of additional information, providing insights into recent cinematic contributions and their context within the film database.
