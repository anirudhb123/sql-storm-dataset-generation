WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
),
AggregatedRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        COALESCE(a.actor_count, 0) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(a.actor_count, 0) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedRoles a ON mh.movie_id = a.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 in Year'
        ELSE 'Below Top 5'
    END AS rank_description
FROM 
    RankedMovies rm
WHERE 
    rm.actor_count IS NOT NULL
    AND rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;