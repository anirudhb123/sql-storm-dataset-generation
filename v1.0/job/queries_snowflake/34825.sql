
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),

cast_stats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN pi.info_type_id = 1 THEN ci.person_id END) AS lead_roles
    FROM cast_info ci
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    GROUP BY ci.movie_id
),

movies_with_keywords AS (
    SELECT 
        mt.id,
        mt.title,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mt.id
),

final_benchmark AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.lead_roles,
        COALESCE(mkw.keywords, ARRAY_CONSTRUCT()) AS keywords_array,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.lead_roles DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN movies_with_keywords mkw ON mh.movie_id = mkw.id
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.total_cast,
    fb.lead_roles,
    fb.keywords_array,
    fb.rank
FROM final_benchmark fb
WHERE fb.total_cast IS NOT NULL
AND fb.production_year BETWEEN 2000 AND 2023
ORDER BY fb.rank, fb.production_year DESC;
