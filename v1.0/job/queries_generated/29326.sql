SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(m.movie_id) AS movie_count,
    AVG(CASE WHEN i.info_type_id = 1 THEN LENGTH(i.info) ELSE NULL END) AS avg_info_length
FROM 
    title t
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    person_info i ON a.person_id = i.person_id
WHERE 
    t.production_year >= 2000
    AND LENGTH(a.name) > 5
GROUP BY 
    t.title, a.name, r.role
HAVING 
    COUNT(m.movie_id) > 1 
ORDER BY 
    movie_count DESC, avg_info_length DESC
LIMIT 100;

This query explores the intersection of movies, their actors, roles, and keywords, aggregating the data to benchmark string processing on names and titles, while applying various filters, joins, and aggregate functions to yield a comprehensive overview of selected movies produced after the year 2000.
