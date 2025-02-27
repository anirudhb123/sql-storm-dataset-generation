WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        rt.role,
        COUNT(*) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ci.role_id, rt.role
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
    kr.role,
    kr.total_cast,
    mk.keywords,
    CASE 
        WHEN mh.depth > 1 THEN 'Sequel/Related'
        ELSE 'Standalone'
    END AS movie_classification
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_roles kr ON mh.movie_id = kr.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND (mk.keywords IS NULL OR mk.keywords LIKE '%Action%')
ORDER BY 
    mh.production_year DESC, 
    kr.total_cast DESC NULLS LAST;
