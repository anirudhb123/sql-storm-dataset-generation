WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS level, 
           CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    UNION ALL
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           mh.level + 1,
           CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
movie_key_data AS (
    SELECT m.id AS movie_id, COALESCE(kw.keyword, 'No Keyword') AS keyword
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
),
person_with_roles AS (
    SELECT ci.id AS cast_id, a.name AS actor_name, 
           rt.role AS role_name, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
filtered_movies AS (
    SELECT mh.movie_id, mh.title, mh.production_year, 
           COUNT(mkd.keyword) AS keyword_count,
           STRING_AGG(DISTINCT pwr.actor_name, ', ') AS actors_list,
           MAX(pwr.actor_rank) AS max_actor_rank
    FROM movie_hierarchy mh
    LEFT JOIN movie_key_data mkd ON mh.movie_id = mkd.movie_id
    LEFT JOIN person_with_roles pwr ON mh.movie_id = pwr.cast_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
)
SELECT f.movie_id, f.title, f.production_year, f.keyword_count, 
       f.actors_list,
       CASE 
           WHEN f.max_actor_rank >= 3 THEN 'Top Cast'
           WHEN f.max_actor_rank IS NULL THEN 'No Cast'
           ELSE 'Supporting Cast'
       END AS cast_status
FROM filtered_movies f
WHERE f.keyword_count > 0
ORDER BY f.production_year DESC, f.title;
