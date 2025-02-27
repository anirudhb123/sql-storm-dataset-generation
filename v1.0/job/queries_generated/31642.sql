WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 5  -- Limit to depth of 5
),
cast_details AS (
    SELECT ci.movie_id, a.name AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),
company_details AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
filtered_movie_info AS (
    SELECT m.movie_id, m.title, m.production_year, 
           cd.actor_name, cd.actor_rank, 
           c.company_name, c.company_type
    FROM movie_hierarchy m
    LEFT JOIN cast_details cd ON m.movie_id = cd.movie_id
    LEFT JOIN company_details c ON m.movie_id = c.movie_id
)
SELECT f.movie_id, f.title, f.production_year, 
       COUNT(DISTINCT f.actor_name) AS total_actors,
       STRING_AGG(DISTINCT f.company_name, ', ') AS company_names,
       MAX(f.actor_rank) AS highest_rank
FROM filtered_movie_info f
WHERE f.company_type IS NOT NULL
GROUP BY f.movie_id, f.title, f.production_year
HAVING COUNT(DISTINCT f.actor_name) > 5
ORDER BY f.production_year DESC, total_actors DESC
LIMIT 50;
