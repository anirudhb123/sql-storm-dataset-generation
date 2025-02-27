WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),
ActorsInMovies AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.depth,
    COALESCE(STRING_AGG(DISTINCT aim.actor_name, ', ') FILTER (WHERE aim.actor_order IS NOT NULL), 'No Actors') AS actors,
    rm.rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies aim ON rm.movie_id = aim.movie_title
WHERE 
    rm.depth <= 3 -- Limit to a specific depth for benchmarking
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.depth, rm.rank
ORDER BY 
    rm.production_year DESC, rm.depth, rm.rank;
