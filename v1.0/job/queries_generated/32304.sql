WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
AggregatedCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mi.id) AS info_count,
        MAX(mi.info) AS last_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ac.total_cast, 0) AS total_cast,
    ac.cast_names,
    mi.info_count,
    mi.last_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AggregatedCast ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.depth < 2
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC
LIMIT 50;

