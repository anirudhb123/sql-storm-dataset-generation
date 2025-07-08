
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.depth < 3  
),
ranked_cast AS (
    SELECT ci.movie_id, ak.name AS actor_name, ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
company_movies AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT mh.movie_id, mh.title, mh.production_year,
       COALESCE(ARRAY_TO_STRING(ARRAY_AGG(DISTINCT cm.company_name), ', '), 'No companies') AS companies,
       COALESCE(ARRAY_TO_STRING(ARRAY_AGG(DISTINCT rc.actor_name), ', '), 'No cast') AS cast,
       COUNT(DISTINCT rc.actor_name) AS actor_count
FROM movie_hierarchy mh
LEFT JOIN company_movies cm ON mh.movie_id = cm.movie_id
LEFT JOIN ranked_cast rc ON mh.movie_id = rc.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year
HAVING COUNT(DISTINCT rc.actor_name) > 0
ORDER BY mh.production_year DESC, mh.title
LIMIT 100;
