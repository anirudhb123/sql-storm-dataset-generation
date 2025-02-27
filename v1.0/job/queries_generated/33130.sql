WITH RECURSIVE ActorHierarchy AS (
    -- Base case: Selecting primary actors
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    WHERE 
        an.name LIKE 'A%'  -- Start with actors whose name starts with 'A'
    
    UNION ALL

    -- Recursive case: Finding related actors by movie collaborations
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.person_id <> ah.person_id  -- Avoid repeating the same actor
),

MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    GROUP BY 
        m.id
)

SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    ah.person_id AS related_actor,
    ah.level AS collaboration_level
FROM 
    MovieDetails md
LEFT JOIN 
    ActorHierarchy ah ON md.movie_id = ah.movie_id
WHERE 
    md.actor_count > 5  -- Only considering movies with more than 5 actors
ORDER BY 
    md.production_year DESC,
    md.title ASC;
