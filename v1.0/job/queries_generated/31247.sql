WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year > 2000
    UNION ALL
    SELECT mt.id AS movie_id, mt.title, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
cast_with_roles AS (
    SELECT ci.movie_id, ak.name AS actor_name, rt.role, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS role_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
keyword_counts AS (
    SELECT mk.movie_id, COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT mh.movie_id, mh.title, COUNT(cwr.actor_name) AS actor_count, 
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       MAX(cwr.role_rank) AS highest_role_rank
FROM movie_hierarchy mh
LEFT JOIN cast_with_roles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN keyword_counts kc ON mh.movie_id = kc.movie_id
GROUP BY mh.movie_id, mh.title
HAVING COUNT(cwr.actor_name) > 2
ORDER BY keyword_count DESC, actor_count ASC;
