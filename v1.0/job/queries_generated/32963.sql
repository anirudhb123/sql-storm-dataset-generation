WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000  -- Start from movies produced after 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        mh.level
    FROM MovieHierarchy mh
    LEFT JOIN ActorCount ac ON mh.movie_id = ac.movie_id
    JOIN title t ON mh.movie_id = t.id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.actor_count,
    CASE 
        WHEN mi.actor_count < 1 THEN 'No actors'
        WHEN mi.actor_count BETWEEN 1 AND 5 THEN 'Low cast'
        WHEN mi.actor_count BETWEEN 6 AND 15 THEN 'Moderate cast'
        ELSE 'Large cast'
    END AS cast_size,
    ARRAY_AGG(DISTINCT a.name) AS actor_names
FROM MovieInfo mi
LEFT JOIN cast_info ci ON mi.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
GROUP BY 
    mi.title, 
    mi.production_year, 
    mi.actor_count, 
    mi.level
ORDER BY 
    mi.production_year DESC, 
    mi.actor_count DESC;
