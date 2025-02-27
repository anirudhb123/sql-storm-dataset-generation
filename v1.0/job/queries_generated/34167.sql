WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        1 AS level
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),

AggregatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        m.movie_id, m.title, m.production_year
),

RankedMovies AS (
    SELECT 
        am.title,
        am.production_year,
        am.cast_count,
        ROW_NUMBER() OVER (PARTITION BY am.production_year ORDER BY am.cast_count DESC) AS rank
    FROM 
        AggregatedMovies am
    WHERE 
        am.cast_count IS NOT NULL
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 in Year'
        ELSE 'Below Top 5'
    END AS rank_category,
    COALESCE(rm.cast_count, 'Not Available') AS cast_count_display,
    'Movie: ' || rm.title || ' (Year: ' || rm.production_year || ')' AS movie_display
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;

