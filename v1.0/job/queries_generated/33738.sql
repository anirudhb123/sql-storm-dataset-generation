WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(mh.level, 0) AS hierarchy_level,
        ci.total_cast,
        ci.actors
    FROM 
        aka_title m
    LEFT JOIN 
        MovieHierarchy mh ON m.id = mh.movie_id
    LEFT JOIN 
        CastWithRoles ci ON m.id = ci.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.hierarchy_level,
    COALESCE(mi.total_cast, 0) AS total_cast_members,
    CASE 
        WHEN mi.hierarchy_level > 1 THEN 'Part of a Franchise'
        ELSE 'Standalone Movie'
    END AS movie_type,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mi.id) AS keyword_count
FROM 
    MovieInfo mi
WHERE 
    mi.hierarchy_level <= 3 
ORDER BY 
    mi.hierarchy_level DESC, mi.total_cast DESC
LIMIT 10;
