
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        NULL AS parent_movie_id
    FROM aka_title mt
    WHERE mt.kind_id = 1 

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id
    FROM aka_title m
    INNER JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),

cast_with_role AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
),

movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

movies_with_keyword AS (
    SELECT 
        mv.movie_id,
        mv.movie_title,
        mv.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = mv.movie_id) AS total_cast
    FROM movie_hierarchy mv
    LEFT JOIN movie_keyword_counts mkc ON mv.movie_id = mkc.movie_id
)

SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.keyword_count,
    mwk.total_cast,
    AVG(CASE WHEN cwr.role_name IS NOT NULL THEN cwr.actor_rank ELSE NULL END) AS avg_role_rank,
    COUNT(DISTINCT cwr.person_id) AS distinct_actors
FROM movies_with_keyword mwk
LEFT JOIN cast_with_role cwr ON mwk.movie_id = cwr.movie_id
WHERE mwk.keyword_count > 5 
  AND mwk.total_cast > 2
  AND mwk.production_year BETWEEN 2000 AND 2023 
GROUP BY mwk.movie_title, mwk.production_year, mwk.keyword_count, mwk.total_cast
ORDER BY mwk.production_year DESC, avg_role_rank DESC
LIMIT 50;
