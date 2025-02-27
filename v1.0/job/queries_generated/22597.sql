WITH RECURSIVE movie_hierarchy AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 1 AS depth
    FROM aka_title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.linked_movie_id, a.title, a.production_year, mh.depth + 1
    FROM movie_link mt
    JOIN movie_hierarchy mh ON mt.movie_id = mh.movie_id
    JOIN aka_title a ON a.id = mt.linked_movie_id
),
cast_roles AS (
    SELECT ci.movie_id, 
           ci.person_id, 
           rt.role, 
           ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
),
super_cast AS (
    SELECT cr.movie_id,
           STRING_AGG(DISTINCT ak.name, ', ') AS actors,
           COUNT(DISTINCT cr.person_id) AS actor_count
    FROM cast_roles cr
    JOIN aka_name ak ON cr.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    GROUP BY cr.movie_id
),
movie_info_summary AS (
    SELECT mi.movie_id, 
           MAX(CASE WHEN it.info = 'runtime' THEN mi.info END) AS runtime,
           MAX(CASE WHEN it.info = 'genre' THEN mi.info END) AS genre,
           MAX(CASE WHEN it.info = 'language' THEN mi.info END) AS language
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)

SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(ms.actors, 'No Cast Available') AS cast,
       ms.actor_count,
       COALESCE(mis.runtime, 'Unknown') AS runtime,
       COALESCE(mis.genre, 'Unknown') AS genre,
       COALESCE(mis.language, 'Unknown') AS language,
       mh.depth
FROM movie_hierarchy mh
LEFT JOIN super_cast ms ON mh.movie_id = ms.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE mh.production_year > 2000
  AND (ms.actor_count IS NULL OR ms.actor_count > 5)
ORDER BY mh.production_year DESC, mh.depth ASC;
