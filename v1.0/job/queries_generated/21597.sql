WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
),
actor_counts AS (
    SELECT ai.person_id, COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name ai ON ci.person_id = ai.person_id
    GROUP BY ai.person_id
),
unique_movie_info AS (
    SELECT 
        mt.title,
        mt.production_year,
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = mt.id) AS company_count,
        (SELECT COUNT(DISTINCT mk.keyword_id) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = mt.id) AS keyword_count
    FROM aka_title mt
),
ranked_actors AS (
    SELECT 
        ai.name, 
        a.movie_count,
        ROW_NUMBER() OVER (PARTITION BY ai.name ORDER BY a.movie_count DESC) AS actor_rank
    FROM actor_counts a
    JOIN aka_name ai ON a.person_id = ai.person_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    u.company_count,
    u.keyword_count,
    ra.name AS top_actor,
    ra.movie_count
FROM movie_hierarchy mh
LEFT JOIN unique_movie_info u ON mh.movie_id = u.movie_id
LEFT JOIN ranked_actors ra ON u.keyword_count > 5 AND ra.actor_rank = 1
WHERE 
    u.company_count IS NOT NULL
    AND (mh.level = 1 OR rainfall_average IS NULL)
ORDER BY 
    mh.production_year DESC,
    u.keyword_count DESC,
    ra.movie_count DESC;
