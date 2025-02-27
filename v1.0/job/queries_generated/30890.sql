WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ab.title,
        ab.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ab ON ml.linked_movie_id = ab.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
), CastInfoAggregated AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    CA.actor_count,
    CA.actors,
    rm.depth,
    CASE 
        WHEN rm.depth > 0 THEN 'Linked Movie'
        ELSE 'Original Movie'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoAggregated CA ON rm.movie_id = CA.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.depth, rm.production_year DESC;

