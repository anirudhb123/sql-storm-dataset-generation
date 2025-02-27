WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level 
    FROM aka_title mt 
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year, 
        mh.level + 1 
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ci.nr_order) AS max_order
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movies_with_keywords AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cs.total_cast,
        cs.max_order,
        kc.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC, kc.keyword_count DESC) AS rn,
        COALESCE(ARRAY_AGG(DISTINCT mwk.keyword_id) FILTER (WHERE mwk.keyword_id IS NOT NULL), '{}') AS keywords
    FROM movie_hierarchy mh
    LEFT JOIN cast_statistics cs ON mh.movie_id = cs.movie_id
    LEFT JOIN keyword_count kc ON mh.movie_id = kc.movie_id
    LEFT JOIN movie_keyword mwk ON mh.movie_id = mwk.movie_id
    GROUP BY mh.movie_id, mh.movie_title, mh.production_year, cs.total_cast, cs.max_order, kc.keyword_count
)
SELECT 
    mw.movie_title,
    mw.production_year,
    mw.total_cast,
    mw.max_order,
    mw.keyword_count,
    mw.keywords,
    CASE 
        WHEN mw.rn <= 10 THEN 'Top Rated' 
        ELSE 'N/A' 
    END AS rating_category
FROM movies_with_keywords mw
WHERE mw.production_year IS NOT NULL
ORDER BY mw.production_year DESC, mw.keyword_count DESC, mw.total_cast DESC;
