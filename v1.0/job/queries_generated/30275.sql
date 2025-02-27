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
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), CastRoleCount AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci 
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
), MovieKeywords AS (
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
    mh.title,
    mh.production_year,
    k.keywords,
    cr.role,
    cr.role_count,
    COUNT(DISTINCT ci.person_id) AS unique_people,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    CastRoleCount cr ON ci.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords k ON mh.movie_id = k.movie_id
WHERE 
    mh.level = 1 
    AND cr.role_count IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, k.keywords, cr.role, cr.role_count
ORDER BY 
    mh.production_year DESC, unique_people DESC;
