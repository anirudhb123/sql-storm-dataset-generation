WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        mt.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link mt
    JOIN 
        MovieHierarchy mh ON mt.movie_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS leading_role_ratio
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.actor_count, 0) AS actor_count,
        COALESCE(mc.leading_role_ratio, 0.0) AS leading_role_ratio
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        MovieCast mc ON m.id = mc.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.keywords,
    mi.actor_count,
    mi.leading_role_ratio,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.role_id IS NOT NULL) AS leading_actors_count
FROM 
    MovieHierarchy mh
JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
WHERE 
    mi.actor_count > 5
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mi.keywords, mi.actor_count, mi.leading_role_ratio
ORDER BY 
    mi.actor_count DESC, mh.production_year DESC;
