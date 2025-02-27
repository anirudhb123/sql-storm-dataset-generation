WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year = 2023
    
    UNION ALL
    
    SELECT mt.movie_id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.movie_id
    WHERE mh.level < 5
),
actor_movie_counts AS (
    SELECT ci.person_id, COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
),
top_actors AS (
    SELECT ak.name, ac.movie_count
    FROM aka_name ak
    JOIN actor_movie_counts ac ON ak.person_id = ac.person_id
    WHERE ac.movie_count > 5
),
movie_details AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           ARRAY_AGG(DISTINCT ak.name) AS actor_names,
           COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id
)
SELECT md.title, md.production_year, 
       md.actor_names, md.keyword_count, 
       th.name AS top_actor_name
FROM movie_details md
LEFT JOIN top_actors th ON th.movie_count > 10
WHERE md.keyword_count > 5 
ORDER BY md.production_year DESC, md.keyword_count DESC
LIMIT 50;

