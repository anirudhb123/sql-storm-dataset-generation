WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.role_id IS NOT NULL
    
    UNION ALL

    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.person_id <> ah.person_id
        AND c.role_id IS NOT NULL
)

SELECT 
    mv.title,
    mv.production_year,
    COUNT(DISTINCT ah.actor_name) AS total_actors,
    AVG(ah.level) AS avg_actor_level,
    STRING_AGG(DISTINCT a.name, ', ') AS lead_actors
FROM 
    title mv
LEFT JOIN 
    complete_cast cc ON mv.id = cc.movie_id
LEFT JOIN 
    ActorHierarchy ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    aka_name a ON ah.person_id = a.person_id
WHERE 
    mv.production_year IS NOT NULL
GROUP BY 
    mv.title, 
    mv.production_year
HAVING 
    COUNT(DISTINCT ah.actor_name) > 2
ORDER BY 
    avg_actor_level DESC, 
    total_actors DESC
LIMIT 10;

SELECT 
    ln.link AS link_type,
    t.title AS movie_title,
    COUNT(DISTINCT m.movie_id) AS linked_movies_count
FROM 
    movie_link m
JOIN 
    link_type ln ON m.link_type_id = ln.id
JOIN 
    title t ON m.linked_movie_id = t.id
GROUP BY 
    ln.link, 
    t.title
HAVING 
    COUNT(DISTINCT m.linked_movie_id) > 3
ORDER BY 
    linked_movies_count DESC;

SELECT 
    ai.movie_id,
    COUNT(DISTINCT ai.person_id) AS total_cast,
    SUM(CASE WHEN ai.role_id IS NOT NULL THEN 1 ELSE 0 END) AS credited_roles
FROM 
    cast_info ai
JOIN 
    aka_title at ON ai.movie_id = at.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = ai.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    )
GROUP BY 
    ai.movie_id
HAVING 
    credited_roles > total_cast/2;
