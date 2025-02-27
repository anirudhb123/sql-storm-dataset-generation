WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
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
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast Available') AS cast_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2010 AND 2019 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.title IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    mh.title
LIMIT 100;