WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        0 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id = (SELECT id FROM aka_title WHERE title = 'Inception' LIMIT 1)  

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.person_id  
    JOIN 
        aka_name a ON c.person_id = a.person_id
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT c2.movie_id) AS movies_worked_with,
    SUM(CASE WHEN a.kind_id IS NULL THEN 1 ELSE 0 END) AS uncredited_roles,
    STRING_AGG(DISTINCT ak.keyword, ', ') AS associated_keywords,
    MAX(a.production_year) AS latest_movie_year,
    RANK() OVER (ORDER BY COUNT(DISTINCT c2.movie_id) DESC) AS rank_by_collaborations
FROM 
    actor_hierarchy ah
LEFT JOIN 
    cast_info c2 ON ah.person_id = c2.person_id
LEFT JOIN 
    aka_title a ON c2.movie_id = a.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword ak ON mk.keyword_id = ak.id
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(DISTINCT c2.movie_id) > 1 
ORDER BY 
    rank_by_collaborations
LIMIT 10;