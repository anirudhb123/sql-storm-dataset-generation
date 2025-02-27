WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

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
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_statistics AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_aggregates AS (
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
    COALESCE(cs.unique_roles, 0) AS unique_roles,
    COALESCE(ka.keywords, 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_statistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_aggregates ka ON mh.movie_id = ka.movie_id
WHERE 
    mh.level <= 3 
    AND mh.production_year BETWEEN 2010 AND 2020
ORDER BY 
    mh.production_year, 
    mh.title;
