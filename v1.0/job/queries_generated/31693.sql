WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1 AS level,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ExpandedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(ARRAY_AGG(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL), '{}') AS aliases,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        MIN(mt.production_year) AS first_production_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        aka_title at ON mh.movie_id = at.id
    LEFT JOIN 
        cast_info cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.level
),
RankedMovies AS (
    SELECT 
        em.*,
        RANK() OVER (PARTITION BY em.level ORDER BY em.cast_count DESC) AS rank_by_cast_size,
        RANK() OVER (ORDER BY em.first_production_year DESC) AS rank_by_year
    FROM 
        ExpandedMovies em
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.level,
    rm.aliases,
    rm.cast_count,
    rm.first_production_year,
    rm.rank_by_cast_size,
    rm.rank_by_year
FROM 
    RankedMovies rm
WHERE 
    rm.rank_by_cast_size <= 5 
    OR rm.rank_by_year <= 5
ORDER BY 
    rm.level, rm.cast_count DESC;
