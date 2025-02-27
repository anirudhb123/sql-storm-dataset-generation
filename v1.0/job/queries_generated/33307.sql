WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.episode_of_id, 
           mt.season_nr, mt.episode_nr, 1 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    UNION ALL
    SELECT a.id AS movie_id, a.title, a.production_year, a.episode_of_id, 
           a.season_nr, a.episode_nr, mh.level + 1
    FROM aka_title a
    JOIN movie_hierarchy mh ON a.episode_of_id = mh.movie_id
),
actor_info AS (
    SELECT ak.name AS actor_name, c.movie_id, 
           RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
),
movie_keywords AS (
    SELECT m.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
movie_company_info AS (
    SELECT m.movie_id, GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    GROUP BY m.movie_id
)
SELECT mh.movie_id, mh.title, mh.production_year, 
       COALESCE(ai.actor_name, 'No Actor') AS actor_name,
       COALESCE(mk.keywords, 'No Keywords') AS keywords,
       COALESCE(mci.company_names, 'No Companies') AS company_names,
       CASE 
           WHEN mh.level > 1 THEN 'Episode'
           ELSE 'Movie'
       END AS type,
       COUNT(DISTINCT ai.role_rank) AS distinct_roles
FROM movie_hierarchy mh
LEFT JOIN actor_info ai ON mh.movie_id = ai.movie_id
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN movie_company_info mci ON mh.movie_id = mci.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, ai.actor_name, mk.keywords, mci.company_names, mh.level
HAVING COUNT(DISTINCT ai.role_rank) > 0
ORDER BY mh.production_year DESC, mh.title ASC
LIMIT 50;
