WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

ActorInformation AS (
    SELECT 
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS featured_movies
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        ak.id
),

MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ai.actor_id) AS actor_count,
        AVG(ai.movie_count) AS avg_movies_per_actor
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorInformation ai ON mh.movie_id = ai.movie_id
    GROUP BY 
        mh.movie_id
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    COALESCE(ms.actor_count, 0) AS total_actors,
    COALESCE(ms.avg_movies_per_actor, 0) AS avg_movies_per_actor,
    CASE 
        WHEN ms.actor_count IS NOT NULL AND ms.avg_movies_per_actor > 3 THEN 'Popular'
        WHEN ms.actor_count IS NULL THEN 'No Actors'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    MovieStats ms
WHERE 
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ms.production_year DESC,
    ms.actor_count DESC NULLS LAST;
