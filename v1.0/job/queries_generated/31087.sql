WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL 
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255))
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3
        AND at.production_year >= 2000
), 
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.path,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),
ActorsByMovie AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.path,
    a.actor_name,
    a.actor_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsByMovie a ON rm.movie_id = a.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.level, 
    rm.production_year DESC, 
    a.actor_rank;
