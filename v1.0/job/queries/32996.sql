WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(ac.total_cast, 0) AS total_cast,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COALESCE(ac.total_cast, 0) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedCast ac ON mh.movie_id = ac.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ti.info AS movie_info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info ti ON t.id = ti.movie_id
    WHERE 
        ti.info_type_id IN (SELECT id FROM info_type WHERE info IN ('plot', 'summary'))
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.total_cast,
    rm.level,
    rm.rank,
    ti.production_year,
    ti.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    TitleInfo ti ON rm.movie_id = ti.movie_id
WHERE 
    rm.level = 0 
ORDER BY 
    rm.rank, rm.title;