WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mh.level < 5
),

company_movie_count AS (
    SELECT mc.movie_id, COUNT(DISTINCT cm.company_id) AS company_count
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.name IS NOT NULL
    GROUP BY mc.movie_id
),

detailed_cast AS (
    SELECT c.movie_id, 
           a.name AS actor_name,
           rk.role AS role_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type rk ON c.role_id = rk.id
    WHERE c.note IS NULL
)

SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COUNT(DISTINCT dc.actor_name) AS total_actors,
       COALESCE(cc.company_count, 0) AS total_companies,
       SUM(CASE 
              WHEN d.rc.role_order = 1 THEN 1 
              ELSE 0 
           END) AS lead_roles,
       STRING_AGG(DISTINCT dk.keyword, ', ') AS associated_keywords
FROM movie_hierarchy mh
LEFT JOIN detailed_cast dc ON mh.movie_id = dc.movie_id
LEFT JOIN company_movie_count cc ON mh.movie_id = cc.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword dk ON mk.keyword_id = dk.id
WHERE mh.production_year > 2000
GROUP BY mh.movie_id, mh.title, mh.production_year, cc.company_count
HAVING COUNT(DISTINCT dc.actor_name) > 3
ORDER BY mh.production_year DESC, total_actors DESC
LIMIT 100;
