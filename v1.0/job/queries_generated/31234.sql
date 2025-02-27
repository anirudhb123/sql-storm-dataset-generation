WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        0 AS level
    FROM 
        aka_name p
    INNER JOIN 
        cast_info c ON p.person_id = c.person_id
    WHERE 
        p.name IS NOT NULL

    UNION ALL

    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        ah.level + 1
    FROM 
        aka_name p
    INNER JOIN 
        cast_info c ON p.person_id = c.person_id
    INNER JOIN 
        ActorHierarchy ah ON c.movie_id = ah.person_id  -- Assuming the movie_id links back to another person
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    ARRAY_AGG(DISTINCT m.title) AS movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) END) AS avg_info_length,
    MAX(m.production_year) AS latest_movie_year,
    MIN(m.production_year) AS earliest_movie_year
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.actor_name
ORDER BY 
    movie_count DESC
LIMIT 10;

