WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id,
        c.role_id,
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.role_id IS NOT NULL

    UNION ALL

    SELECT 
        c2.person_id, 
        c2.movie_id,
        c2.role_id,
        ah.level + 1
    FROM 
        cast_info c2
    JOIN ActorHierarchy ah ON ah.movie_id = c2.movie_id
    WHERE 
        c2.role_id IS NOT NULL AND 
        c2.person_id <> ah.person_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(director.name, 'Unknown') AS director_name,
    COUNT(DISTINCT ah2.person_id) AS co_actor_count,
    SUM(CASE WHEN m.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ah.person_id) DESC) AS rank_by_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    (SELECT movie_id, ARRAY_AGG(name) AS name FROM company_name GROUP BY movie_id) director ON director.company_id = (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director') LIMIT 1)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    ActorHierarchy ah ON ah.movie_id = ci.movie_id
LEFT JOIN 
    (SELECT movie_id, note FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Comment')) m ON m.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, director.name
HAVING 
    COUNT(DISTINCT ah2.person_id) > 5
ORDER BY 
    t.production_year DESC, co_actor_count DESC;
