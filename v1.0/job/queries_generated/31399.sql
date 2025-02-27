WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mk.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    WHERE 
        mk.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(cs.total_actors, 0) AS total_actors,
        COALESCE(cs.actor_names, 'No actors found') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStats cs ON mh.movie_id = cs.movie_id
)
SELECT 
    mwi.movie_id,
    mwi.title,
    mwi.level,
    mwi.total_actors,
    CASE 
        WHEN mwi.level = 1 THEN 'Original Movie'
        ELSE 'Linked Movie'
    END AS movie_type,
    CASE 
        WHEN mwi.total_actors > 5 THEN 'Popular Movie'
        ELSE 'Less Popular Movie'
    END AS popularity,
    mwi.actor_names
FROM 
    MoviesWithInfo mwi
WHERE 
    mwi.total_actors IS NOT NULL
ORDER BY 
    mwi.level, mwi.total_actors DESC;

-- Benchmarking performance by including various joins and aggregations
EXPLAIN ANALYZE 
WITH RecursiveTitles AS (
    SELECT 
        title.id, title.title, title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS row_num
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.id AS title_id,
    rt.title,
    rt.production_year,
    ac.actor_count
FROM 
    RecursiveTitles rt
LEFT JOIN 
    ActorMovieCount ac ON rt.id = ac.movie_id
WHERE 
    ac.actor_count > 3
ORDER BY 
    rt.production_year DESC, ac.actor_count DESC;
