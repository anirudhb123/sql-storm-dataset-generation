WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 
           1 AS level, 
           CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT m.movie_id, m.title, m.production_year, 
           mh.level + 1,
           CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_summary AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_summary AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    m.id AS movie_id, 
    m.title AS movie_title, 
    m.production_year, 
    mh.level,
    COALESCE(cs.actor_count, 0) AS num_actors,
    COALESCE(ks.keywords, 'No Keywords') AS keyword_list,
    RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_in_year,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year' 
        ELSE 'Known Year'
    END AS year_status
FROM aka_title m
LEFT JOIN movie_hierarchy mh ON m.id = mh.movie_id
LEFT JOIN cast_summary cs ON m.id = cs.movie_id
LEFT JOIN keyword_summary ks ON m.id = ks.movie_id
WHERE m.production_year >= 2000
ORDER BY m.production_year DESC, m.title
LIMIT 100;
