WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           0 AS level 
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT mt.id, mt.title, mt.production_year, 
           mh.level + 1 
    FROM aka_title mt
    INNER JOIN movie_link ml ON ml.movie_id = mh.movie_id
    INNER JOIN aka_title m ON ml.linked_movie_id = m.id
    INNER JOIN movie_companies mc ON mc.movie_id = m.id
    WHERE mh.level < 5
),
cast_performance AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS total_cast_members,
           STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info ci
    INNER JOIN aka_name ak ON ak.person_id = ci.person_id
    GROUP BY ci.movie_id
),
movie_details AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           COALESCE(cp.total_cast_members, 0) AS total_cast,
           COALESCE(cp.cast_names, 'No Cast') AS cast_list,
           ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM aka_title m
    LEFT JOIN cast_performance cp ON cp.movie_id = m.id
    WHERE m.production_year BETWEEN 2000 AND 2023
)
SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       md.total_cast, 
       md.cast_list
FROM movie_hierarchy mh
LEFT JOIN movie_details md ON md.movie_id = mh.movie_id
WHERE mh.level = 0
ORDER BY md.production_year DESC, md.total_cast DESC, mh.title
LIMIT 50;
