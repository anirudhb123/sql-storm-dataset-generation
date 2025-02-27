WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),

CastWithRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        cr.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type cr ON ci.role_id = cr.id
),

AggregatedMovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT cw.person_id) AS total_cast,
        STRING_AGG(DISTINCT CASE WHEN cw.role_type IS NOT NULL THEN cw.role_type ELSE 'Unknown' END, ', ') AS roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRole cw ON mh.movie_id = cw.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    am.movie_id,
    am.title,
    am.production_year,
    am.total_cast,
    am.roles,
    COALESCE(NULLIF(am.total_cast, 0), NULL) AS safe_cast_count
FROM 
    AggregatedMovieData am
WHERE 
    am.production_year = 2023
ORDER BY 
    am.total_cast DESC NULLS LAST
LIMIT 10;
