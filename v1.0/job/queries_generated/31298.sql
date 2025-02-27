WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title AS movie_title, m.production_year,
           1 AS depth
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title AS movie_title, m.production_year,
           mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_roles AS (
    SELECT ci.movie_id, ci.role_id,
           COUNT(DISTINCT p.id) AS num_actors,
           STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name a ON a.person_id = ci.person_id
    JOIN role_type r ON r.id = ci.role_id
    LEFT JOIN movie_companies mc ON mc.movie_id = ci.movie_id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    WHERE mc.company_id IS NULL
    GROUP BY ci.movie_id, ci.role_id
),
movie_details AS (
    SELECT m.id AS movie_id, m.title, 
           COALESCE(SUM(CASE WHEN r.kind IS NOT NULL THEN 1 ELSE 0 END), 0) AS num_roles,
           AVG(m.production_year) OVER() AS average_year,
           ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_ranking
    FROM aka_title m
    LEFT JOIN cast_info ci ON ci.movie_id = m.id
    LEFT JOIN role_type r ON r.id = ci.role_id
    GROUP BY m.id
)
SELECT mh.movie_title, 
       mh.production_year, 
       md.num_roles, 
       md.average_year, 
       md.title_ranking,
       cr.num_actors, 
       cr.actor_names
FROM movie_hierarchy mh
LEFT JOIN movie_details md ON md.movie_id = mh.movie_id
LEFT JOIN cast_roles cr ON cr.movie_id = mh.movie_id
WHERE mh.depth <= 2 
  AND md.num_roles > 0
  AND cr.num_actors > 0
ORDER BY mh.production_year DESC, md.title_ranking;
