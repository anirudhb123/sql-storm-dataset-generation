
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        t.title AS path
    FROM 
        aka_title t
    WHERE 
        t.production_year > 1990
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.path || ' -> ' || mt.title
    FROM 
        movie_link m
    JOIN 
        aka_title mt ON m.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        mh.path,
        ROW_NUMBER() OVER (PARTITION BY mh.path ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.path,
    cd.actor_count,
    cd.actors
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    cd.actor_count IS NOT NULL
    AND rm.rn = 1
ORDER BY 
    rm.path, rm.production_year DESC;
