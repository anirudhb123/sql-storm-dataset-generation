WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS role_rank,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.level AS hierarchy_level,
    COALESCE(rm.production_year, 'Unknown') AS production_year,
    COALESCE(rm.cast_count, 0) AS number_of_cast,
    COALESCE(kc.keyword_count, 0) AS number_of_keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON mh.movie_id = rm.movie_id
LEFT JOIN 
    KeywordCounts kc ON mh.movie_id = kc.movie_id
ORDER BY 
    mh.level, rm.role_rank DESC;

