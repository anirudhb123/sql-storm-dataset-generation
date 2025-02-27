WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limit the recursion to deep links
),
CastWithRole AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(*) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MovieStatistics AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cr.actor_count, 0) AS actor_count,
        COUNT(DISTINCT km.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRole cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, cr.actor_count
),
FullMovieInfo AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC, ms.keyword_count DESC) AS rn
    FROM 
        MovieStatistics ms
)
SELECT 
    fmi.movie_id,
    fmi.title,
    fmi.production_year,
    fmi.actor_count,
    fmi.keyword_count,
    CASE 
        WHEN fmi.actor_count > 0 THEN 'Has Cast'
        ELSE 'No Cast' 
    END AS cast_presence,
    ROW_NUMBER() OVER (ORDER BY fmi.actor_count DESC) AS global_rank
FROM 
    FullMovieInfo fmi
WHERE 
    fmi.actor_count > 0
    AND fmi.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fmi.production_year, fmi.actor_count DESC;
