WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        kt.title,
        kt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN aka_title kt ON ml.linked_movie_id = kt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(an.name, '(', rc.role, ')'), ', ') AS cast_details
    FROM 
        cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type rc ON ci.role_id = rc.id
    GROUP BY 
        ci.movie_id
),
movies_with_info AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cs.cast_count,
        COALESCE(cs.cast_details, 'No Cast Listed') AS cast_details,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.cast_count DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
)
SELECT 
    mw.movie_id,
    mw.movie_title,
    mw.production_year,
    mw.cast_count,
    mw.cast_details,
    COALESCE(k.keyword, 'No Keywords') AS keywords,
    CASE 
        WHEN mw.rank <= 3 THEN 'Top 3 in Year' 
        ELSE 'Other' 
    END AS rank_category
FROM 
    movies_with_info mw
LEFT JOIN movie_keyword mk ON mw.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE 
    mw.cast_count IS NOT NULL 
    AND mw.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mw.production_year DESC, mw.cast_count DESC
LIMIT 100;
