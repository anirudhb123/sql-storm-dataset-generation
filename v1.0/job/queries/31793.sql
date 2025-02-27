WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.kind_id, 
           1 AS level, CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mt.kind_id, 
           mh.level + 1 AS level, 
           CAST(mh.path || ' > ' || mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
    WHERE mh.level < 5 
),
keyword_summary AS (
    SELECT mk.movie_id, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
cast_summary AS (
    SELECT ci.movie_id, STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
complete_info AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 
           k.keywords, c.actors, str.count AS keyword_count
    FROM movie_hierarchy mt
    LEFT JOIN keyword_summary k ON mt.movie_id = k.movie_id
    LEFT JOIN cast_summary c ON mt.movie_id = c.movie_id
    LEFT JOIN LATERAL (
        SELECT COUNT(DISTINCT mk.keyword_id) AS count
        FROM movie_keyword mk
        WHERE mk.movie_id = mt.movie_id
    ) str ON true
)
SELECT ci.title, ci.production_year, ci.keywords, ci.actors, 
       COALESCE(ci.keyword_count, 0) AS keyword_count,
       CASE 
           WHEN ci.keyword_count > 3 THEN 'High'
           WHEN ci.keyword_count BETWEEN 1 AND 3 THEN 'Medium'
           ELSE 'Low'
       END AS keyword_density
FROM complete_info ci
WHERE ci.production_year >= 2000
ORDER BY ci.production_year DESC, ci.title
LIMIT 50;