WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(0 AS INTEGER) AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming '1' represents movies in the `kind_type` table.

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3  -- Limiting the recursion depth to avoid excessive hierarchy.

),

RankedMovies AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY h.movie_id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY h.production_year DESC, h.title) AS rank
    FROM 
        MovieHierarchy h
    LEFT JOIN 
        complete_cast cc ON h.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = h.movie_id
)

SELECT 
    mv.title,
    mv.production_year,
    mv.actor_count,
    COALESCE(cn.name, 'Unknown') AS producer_name,
    CASE 
        WHEN mv.actor_count > 5 THEN 'Ensemble Cast'
        WHEN mv.actor_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_description,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    RankedMovies mv
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mv.production_year BETWEEN 2000 AND 2023
    AND (mv.actor_count IS NULL OR mv.actor_count > 0)
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, mv.actor_count, producer_name
HAVING 
    COUNT(DISTINCT kw.keyword) > 0
ORDER BY 
    cast_description DESC, mv.production_year DESC;

-- Adding a mysterious twist with NULL logic and bizarre deviations in data handling:
SELECT
    *,
    CASE 
        WHEN (mv.actor_count IS NULL OR mv.actor_count = 0) AND mv.production_year IS NOT NULL THEN 'Ghost Movie'
        ELSE 'Known Movie'
    END AS movie_status
FROM 
    (
        SELECT 
            mv.*, 
            RANK() OVER (PARTITION BY mv.production_year ORDER BY mv.actor_count DESC) AS production_rank
        FROM 
            RankedMovies mv
    ) final_mv
WHERE 
    (final_mv.production_year IS NULL OR final_mv.production_rank < 5);
