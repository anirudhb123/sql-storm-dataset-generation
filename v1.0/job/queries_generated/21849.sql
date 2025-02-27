WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
  
    UNION ALL
  
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
),
ranked_cast AS (
    SELECT ci.movie_id,
           ak.name,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank_order,
           COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
),
title_keywords AS (
    SELECT mt.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
),
movie_info_nullable AS (
    SELECT mi.movie_id,
           COALESCE(mi.info, 'No additional info') AS info,
           info_type.info AS info_type
    FROM movie_info mi
    LEFT JOIN info_type ON mi.info_type_id = info_type.id
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       rk.name AS cast_member,
       rk.rank_order,
       rk.total_cast,
       tk.keywords,
       CASE
           WHEN mk.movie_id IS NULL THEN 'No Related Movies'
           ELSE 'Related Movies Exist'
       END AS related_movies_status,
       mi.info AS additional_info,
       CASE
           WHEN mi.info IS NULL THEN 'Info not available'
           ELSE 'Info available'
       END AS info_availability
FROM movie_hierarchy mh
LEFT JOIN ranked_cast rk ON mh.movie_id = rk.movie_id
LEFT JOIN title_keywords tk ON mh.movie_id = tk.movie_id
LEFT JOIN movie_link ml ON mh.movie_id = ml.movie_id
LEFT JOIN aka_title mt ON ml.linked_movie_id = mt.id
LEFT JOIN movie_info_nullable mi ON mh.movie_id = mi.movie_id
WHERE mh.level < 3
  AND (mh.production_year > 2000 OR mh.production_year IS NULL)
ORDER BY mh.production_year DESC, rk.rank_order
LIMIT 50;
