
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, m.kind_id, 1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    UNION ALL
    SELECT m.id, m.title, m.production_year, m.kind_id, mh.level + 1
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
company_movie_info AS (
    SELECT mc.movie_id, 
           c.name AS company_name, 
           ct.kind AS company_type,
           COUNT(DISTINCT mi.info_type_id) AS info_count,
           SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS non_null_info_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi ON mc.movie_id = mi.movie_id
    GROUP BY mc.movie_id, c.name, ct.kind
),
ranked_movies AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank,
           COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY m.id, m.title, m.production_year, m.kind_id
)
SELECT mh.title AS movie_title,
       mh.production_year,
       cm.company_name,
       cm.company_type,
       cm.info_count,
       cm.non_null_info_count,
       rm.rank,
       rm.keyword_count
FROM movie_hierarchy mh
LEFT JOIN company_movie_info cm ON mh.movie_id = cm.movie_id
JOIN ranked_movies rm ON mh.movie_id = rm.movie_id
WHERE mh.production_year > 2000
  AND (rm.rank IS NULL OR rm.rank <= 3)
  AND cm.info_count > 0
ORDER BY mh.production_year ASC, rm.keyword_count DESC;
