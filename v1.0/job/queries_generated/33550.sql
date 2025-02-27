WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        r.role AS role,
        COUNT(*) OVER(PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_count
    FROM 
        cast_info ci
    JOIN role_type r ON ci.role_id = r.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN CastRoles ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(GROUP_CONCAT(DISTINCT CASE WHEN cr.role = 'Director' THEN aka.name END), 'No Director') AS directors,
    COALESCE(GROUP_CONCAT(DISTINCT CASE WHEN cr.role = 'Actor' THEN aka.name END), 'No Actor') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    RankedMovies rm
LEFT JOIN movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN comp_cast_type cct ON ci.person_role_id = cct.id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    rm.cast_count > 0
ORDER BY 
    rm.cast_count DESC, rm.production_year DESC;
