WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000  

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        h.level < 3  
),


ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),


MoviesWithActors AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        a.name AS actor_name,
        a.actor_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorMovies a ON mh.movie_id = a.movie_id
)

SELECT 
    mw.actor_name,
    mw.title,
    mw.production_year,
    COUNT(mw.actor_name) OVER (PARTITION BY mw.title) AS actor_count,
    MIN(mw.production_year) OVER (PARTITION BY mw.title) AS first_year
FROM 
    MoviesWithActors mw
WHERE 
    mw.actor_name IS NOT NULL  
    AND mw.production_year IS NOT NULL
ORDER BY 
    mw.production_year DESC,
    actor_count DESC;