WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        COALESCE(mt.title, 'Unknown Title') AS title,
        mt.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        COALESCE(aka.sub_title, 'Unknown Title') AS title,
        mt2.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title aka ON ml.linked_movie_id = aka.id
    JOIN 
        aka_title mt2 ON mh.movie_id = mt2.id
),

CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),

KeywordAggregation AS (
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
    mh.title,
    mh.production_year,
    COALESCE(ka.name, 'N/A') AS actor_name,
    COALESCE(crc.role_name, 'N/A') AS role_name,
    COALESCE(crc.role_count, 0) AS role_count,
    COALESCE(ka2.name, 'N/A') AS company_name,
    ka.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    CastRoleCounts crc ON mh.movie_id = crc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name ka2 ON mc.company_id = ka2.id
LEFT JOIN 
    KeywordAggregation ka ON mh.movie_id = ka.movie_id
WHERE 
    mh.hierarchy_level = 1
    AND mh.production_year > 2000
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;
