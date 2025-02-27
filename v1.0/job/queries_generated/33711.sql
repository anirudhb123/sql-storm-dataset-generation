WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           0 AS level
    FROM aka_title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT a.id AS movie_id, 
           a.title, 
           a.production_year, 
           mh.level + 1
    FROM aka_title a
    JOIN movie_hierarchy mh ON a.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT ci.movie_id, 
           ak.name AS actor_name, 
           rt.role AS role,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
keyword_counts AS (
    SELECT mk.movie_id, 
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_info AS (
    SELECT mc.movie_id, 
           c.name AS company_name, 
           ct.kind AS company_type,
           COUNT(*) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
)
SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       cd.actor_name,
       cd.role,
       kc.keyword_count,
       co.company_name,
       co.company_type,
       COALESCE(co.company_count, 0) AS total_companies,
       CASE 
           WHEN mh.level > 0 THEN 'Episode'
           ELSE 'Movie'
       END AS movie_type
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN keyword_counts kc ON mh.movie_id = kc.movie_id
LEFT JOIN company_info co ON mh.movie_id = co.movie_id
WHERE (mh.production_year >= 2000 OR co.company_type IS NOT NULL)
ORDER BY mh.production_year DESC, mh.title, cd.actor_order;
