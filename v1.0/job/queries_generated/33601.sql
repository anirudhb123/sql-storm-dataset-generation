WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        c.movie_id AS root_movie_id,
        c.subject_id AS actor_id,
        1 AS depth,
        m.title AS movie_title
    FROM 
        complete_cast c
    JOIN 
        title m ON m.id = c.movie_id
    WHERE 
        c.status_id = 1  -- Only include active movies

    UNION ALL

    SELECT 
        mc.movie_id AS root_movie_id,
        mc.subject_id AS actor_id,
        mh.depth + 1,
        t.title AS movie_title
    FROM 
        MovieHierarchy mh
    JOIN 
        complete_cast mc ON mh.actor_id = mc.subject_id
    JOIN 
        title t ON t.id = mc.movie_id
    WHERE 
        mc.status_id = 1 AND 
        mh.depth < 3 -- Limiting the depth for performance
)
, ActorCounts AS (
    SELECT 
        mh.actor_id,
        COUNT(DISTINCT mh.root_movie_id) AS movie_count
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.actor_id
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    COALESCE(ac.movie_count, 0) AS movies_acted_in
FROM 
    aka_name a
LEFT JOIN 
    ActorCounts ac ON a.person_id = ac.actor_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    movies_acted_in DESC, a.name
LIMIT 50; -- Top 50 actors by movie count

This query showcases a recursive common table expression (CTE) to create a hierarchy of movies based on actors. It then counts the distinct movies each actor has participated in and returns the top 50 actors based on this count, demonstrating various SQL concepts like outer joins, grouping, and ordering.
