WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        ak.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_keyword_count AS (
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
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No cast') AS cast_names,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_by_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_keyword_count mkc ON mh.movie_id = mkc.movie_id
WHERE 
    mh.production_year >= 1990 AND (mh.kind_id IS NOT NULL OR mh.kind_id <> 0)
ORDER BY 
    mh.production_year DESC,
    rank_by_year
LIMIT 50
OFFSET 0;
