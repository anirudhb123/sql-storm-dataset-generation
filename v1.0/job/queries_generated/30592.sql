WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        mh.depth < 5
)
, CastInfoWithRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
, MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    COALESCE(cast_info.person_name, 'Unknown Actor') AS actor_name,
    CUBE(mk.keywords) AS keywords_grouped,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mh.movie_id) AS actor_count,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name na ON ci.person_id = na.person_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
WHERE 
    (mh.depth > 1 OR ci.role_name IS NOT NULL)
    AND mk.keywords IS NOT NULL
ORDER BY 
    mh.movie_title ASC, mh.depth DESC;
