WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.id,
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieInfoAggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_summary,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count 
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cw.actor_name, 'Unknown Actor') AS main_actor,
    cw.role_name,
    mia.info_summary,
    mia.keyword_count,
    COUNT(*) OVER (PARTITION BY mh.movie_id) AS number_of_cast
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfoWithRoles cw ON mh.movie_id = cw.movie_id AND cw.role_order = 1
LEFT JOIN 
    MovieInfoAggregated mia ON mh.movie_id = mia.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;
