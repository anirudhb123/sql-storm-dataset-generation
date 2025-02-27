WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
),
cast_rank AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order,
        (SELECT COUNT(*) FROM cast_info WHERE movie_id = ci.movie_id) AS total_cast
    FROM cast_info ci
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
keyword_analysis AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cr.person_id,
    cr.role_order,
    cs.company_count,
    cs.companies,
    ka.keywords
FROM movie_hierarchy mh
LEFT JOIN cast_rank cr ON mh.movie_id = cr.movie_id
LEFT JOIN company_statistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN keyword_analysis ka ON mh.movie_id = ka.movie_id
WHERE mh.depth = 0
ORDER BY mh.production_year DESC, mh.movie_title, cr.role_order
LIMIT 100;
