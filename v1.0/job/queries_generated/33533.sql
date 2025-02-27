WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Base case: all movies from the year 2000 onwards

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieData AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(rc.role_count, 0) AS role_count,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        mh.level
    FROM 
        MovieHierarchy mv
    LEFT JOIN 
        RoleCounts rc ON mv.movie_id = rc.movie_id
    LEFT JOIN 
        KeywordStats ks ON mv.movie_id = ks.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.role_count,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Highly Tagged'
        WHEN md.keyword_count BETWEEN 1 AND 5 THEN 'Moderately Tagged'
        ELSE 'No Tags'
    END AS tagging_category,
    DENSE_RANK() OVER (PARTITION BY md.level ORDER BY md.role_count DESC) AS role_rank
FROM 
    MovieData md
WHERE 
    md.role_count > 0
ORDER BY 
    md.production_year DESC, 
    role_rank;
