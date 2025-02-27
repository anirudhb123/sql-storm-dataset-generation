WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           ml.linked_movie_id,
           1 AS level
    FROM aka_title mt
    LEFT JOIN movie_link ml ON mt.id = ml.movie_id
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           ml.linked_movie_id,
           level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
cast_info_cte AS (
    SELECT ci.movie_id,
           STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
           COUNT(DISTINCT a.id) AS total_cast
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.nr_order IS NOT NULL
    GROUP BY ci.movie_id
),
keyword_stats AS (
    SELECT mk.movie_id,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_details AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           COALESCE(ci.cast_names, 'No cast info') AS cast_info,
           COALESCE(ks.keywords, 'No keywords') AS keywords,
           ci.total_cast, 
           ks.keyword_count
    FROM movie_hierarchy mh
    LEFT JOIN cast_info_cte ci ON mh.movie_id = ci.movie_id
    LEFT JOIN keyword_stats ks ON mh.movie_id = ks.movie_id
)
SELECT md.title,
       md.production_year,
       md.cast_info,
       md.keywords,
       md.total_cast,
       md.keyword_count,
       CASE 
           WHEN md.total_cast > 0 AND md.keyword_count > 0 THEN 'Active'
           WHEN md.total_cast = 0 AND md.keyword_count = 0 THEN 'Inactive'
           ELSE 'Mixed'
       END AS activity_status
FROM movie_details md
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, md.total_cast DESC
FETCH FIRST 100 ROWS ONLY;
