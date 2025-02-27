WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           COALESCE(mk.keyword, 'No Keywords') AS keyword,
           0 AS level
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    UNION ALL
    SELECT m.id AS movie_id,
           m.title,
           COALESCE(mk.keyword, 'No Keywords') AS keyword,
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE mh.level < 5
),
keyword_counts AS (
    SELECT movie_id, 
           COUNT(keyword) AS keyword_count
    FROM movie_hierarchy
    GROUP BY movie_id
),
cast_info_summary AS (
    SELECT ci.movie_id,
           COUNT(ci.person_id) AS total_cast,
           STRING_AGG(a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
movies_with_details AS (
    SELECT m.id AS movie_id,
           m.title,
           COALESCE(kc.keyword_count, 0) AS keyword_count,
           COALESCE(cs.total_cast, 0) AS total_cast,
           COALESCE(cs.cast_names, 'No Cast Info') AS cast_names,
           CASE 
               WHEN m.production_year IS NULL THEN 'Unknown Year'
               ELSE m.production_year::text
           END AS production_year
    FROM aka_title m
    LEFT JOIN keyword_counts kc ON m.id = kc.movie_id
    LEFT JOIN cast_info_summary cs ON m.id = cs.movie_id
),
final_result AS (
    SELECT movie_id, 
           title,
           keyword_count,
           total_cast,
           cast_names,
           production_year,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_within_year
    FROM movies_with_details
)
SELECT fr.*,
       CASE 
           WHEN fr.keyword_count > 0 THEN 'Has Keywords'
           ELSE 'No Keywords'
       END AS keyword_status,
       CONCAT('Movie: ', fr.title, ', Year: ', fr.production_year) AS movie_description
FROM final_result fr
WHERE fr.total_cast > 0
AND fr.keyword_count IS NOT NULL
ORDER BY production_year, rank_within_year;
