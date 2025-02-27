WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Focus on movies from 2000 onwards

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        p.id AS person_id,
        p.name,
        COALESCE(r.role, 'Unknown Role') AS role_description,
        COUNT(*) OVER(PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ar.person_id,
        ar.name AS actor_name,
        ar.role_description,
        ar.actor_count,
        ROW_NUMBER() OVER(PARTITION BY mh.movie_id ORDER BY ar.actor_count DESC) AS actor_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    STRING_AGG(mi.actor_name || ' (' || mi.role_description || ')', ', ') AS cast,
    MAX(mi.actor_count) AS total_unique_actors
FROM 
    MovieInfo mi
WHERE 
    mi.actor_rank <= 3  -- Only top 3 actors per movie
GROUP BY 
    mi.title, mi.production_year
ORDER BY 
    mi.production_year DESC, 
    total_unique_actors DESC
LIMIT 10;

