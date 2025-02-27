WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, 1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name LIKE 'Tom%'

    UNION ALL

    SELECT c.person_id, ah.level + 1
    FROM cast_info c
    JOIN ActorHierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name NOT LIKE 'Tom%' AND ah.level < 3
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    AVG(m.production_year) AS average_production_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    COALESCE(MAX(m.production_year), 'N/A') AS latest_movie_year,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT m.movie_id) DESC) AS actor_rank
FROM 
    ActorHierarchy ah
JOIN 
    aka_name a ON ah.person_id = a.person_id
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
GROUP BY 
    a.person_id, a.name
HAVING 
    COUNT(DISTINCT m.movie_id) > 2
ORDER BY 
    total_movies DESC, actor_rank;
