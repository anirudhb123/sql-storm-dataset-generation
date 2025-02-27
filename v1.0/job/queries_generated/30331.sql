WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role = 'lead')
    
    UNION ALL
    
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id 
    WHERE 
        c.nr_order > ah.nr_order
),
MovieRankings AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT ca.person_id) AS total_actors,
        AVG(ah.level) AS avg_actor_level,
        MAX(mt.production_year) AS latest_production_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.id = ca.movie_id
    LEFT JOIN 
        ActorHierarchy ah ON ca.person_id = ah.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title
    ORDER BY 
        total_actors DESC
    LIMIT 10
)
SELECT 
    mr.title,
    mr.total_actors,
    mr.avg_actor_level,
    mr.latest_production_year,
    CASE 
        WHEN mr.total_actors > 5 THEN 'Ensemble Cast'
        WHEN mr.total_actors > 0 THEN 'Small Cast'
        ELSE 'No Actors'
    END AS cast_size
FROM 
    MovieRankings mr
WHERE 
    mr.avg_actor_level IS NOT NULL
UNION ALL
SELECT 
    'Unknown Movie' AS title,
    0 AS total_actors,
    NULL AS avg_actor_level,
    NULL AS latest_production_year,
    'No Actors' AS cast_size
WHERE 
    NOT EXISTS (SELECT 1 FROM MovieRankings);
