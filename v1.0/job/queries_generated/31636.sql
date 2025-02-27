WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        title AS t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        t.production_year >= 2000
),
AggregatedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
RankedMovies AS (
    SELECT 
        am.movie_id,
        am.title,
        am.production_year,
        am.cast_count,
        am.actors,
        RANK() OVER (PARTITION BY am.production_year ORDER BY am.cast_count DESC) AS rank_within_year
    FROM 
        AggregatedMovies AS am
)
SELECT 
    rm.production_year,
    rm.title,
    rm.cast_count,
    rm.actors
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank_within_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
