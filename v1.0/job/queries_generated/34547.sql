WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           1 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
movie_keyword_count AS (
    SELECT mk.movie_id, 
           COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
person_movie_roles AS (
    SELECT ci.movie_id, 
           COUNT(DISTINCT ci.person_id) AS total_cast,
           STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.id
    GROUP BY ci.movie_id
),
selected_movies AS (
    SELECT mh.movie_id, 
           mh.title,
           mh.production_year,
           COALESCE(mkc.keyword_count, 0) AS keyword_count,
           COALESCE(pm.total_cast, 0) AS total_cast,
           pm.cast_names
    FROM movie_hierarchy mh
    LEFT JOIN movie_keyword_count mkc ON mh.movie_id = mkc.movie_id
    LEFT JOIN person_movie_roles pm ON mh.movie_id = pm.movie_id
    WHERE mh.production_year >= 2000
)
SELECT sm.title,
       sm.production_year,
       sm.keyword_count,
       sm.total_cast,
       sm.cast_names,
       CASE
           WHEN sm.keyword_count > 5 THEN 'Highly Tagged'
           WHEN sm.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
           ELSE 'Low Tagged'
       END AS tagging_level,
       ROW_NUMBER() OVER (ORDER BY sm.production_year DESC) AS rank
FROM selected_movies sm
WHERE sm.total_cast IS NOT NULL
ORDER BY sm.production_year DESC, sm.keyword_count DESC
LIMIT 10;
