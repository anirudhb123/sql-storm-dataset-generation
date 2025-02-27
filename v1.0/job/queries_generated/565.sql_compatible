
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT m.id, m.title, m.production_year, h.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy h ON ml.movie_id = h.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE h.level < 5
),
cast_roles AS (
    SELECT ci.movie_id, 
           rt.role, 
           COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
average_actor_roles AS (
    SELECT movie_id, 
           AVG(actor_count) AS avg_actor_count
    FROM cast_roles
    GROUP BY movie_id
),
movie_info_summary AS (
    SELECT am.id AS movie_id, 
           am.title, 
           COALESCE(a.avg_actor_count, 0) AS avg_actor_count,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title am
    LEFT JOIN average_actor_roles a ON am.id = a.movie_id
    LEFT JOIN movie_keyword mk ON am.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY am.id, am.title, a.avg_actor_count
)
SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       ms.avg_actor_count, 
       ms.keywords
FROM movie_hierarchy mh
LEFT JOIN movie_info_summary ms ON mh.movie_id = ms.movie_id
WHERE ms.avg_actor_count > (SELECT AVG(avg_actor_count) FROM average_actor_roles) 
  OR mh.level = 1
ORDER BY mh.production_year DESC, mh.title ASC;
