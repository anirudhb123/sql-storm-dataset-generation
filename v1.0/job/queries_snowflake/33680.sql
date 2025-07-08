
WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           NULL AS parent_id
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT a.id AS movie_id, 
           a.title, 
           a.production_year, 
           mh.movie_id AS parent_id
    FROM aka_title a
    JOIN movie_hierarchy mh ON a.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT c.movie_id,
           LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
           COUNT(DISTINCT ak.id) AS actor_count
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY c.movie_id
),
movie_details AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           COALESCE(ca.actor_names, 'No Cast') AS actor_names,
           ca.actor_count
    FROM movie_hierarchy mh
    LEFT JOIN cast_aggregates ca ON mh.movie_id = ca.movie_id
),
yearly_movie_count AS (
    SELECT production_year, COUNT(*) AS total_movies
    FROM movie_details
    GROUP BY production_year
)
SELECT md.title,
       md.production_year,
       md.actor_names,
       ym.total_movies,
       CASE 
           WHEN md.production_year IS NOT NULL THEN 'Year Available'
           ELSE 'Year Not Available'
       END AS year_status,
       ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS row_num
FROM movie_details md
LEFT JOIN yearly_movie_count ym ON md.production_year = ym.production_year
WHERE md.actor_count IS NOT NULL
ORDER BY md.production_year DESC, md.title;
