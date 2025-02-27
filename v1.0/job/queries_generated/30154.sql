WITH RECURSIVE actor_hierarchy AS (
    SELECT p.id AS actor_id, a.name, 1 AS level
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT a.id AS actor_id, a.name, ah.level + 1
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN actor_hierarchy ah ON ah.actor_id = c.person_id
    WHERE t.production_year >= 2000
),
movie_info_summary AS (
    SELECT m.id AS movie_id, m.title, 
           COUNT(DISTINCT ci.person_id) AS total_actors,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           MAX(mi.info) AS notes
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id, m.title
),
actor_movie_counts AS (
    SELECT a.name, COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.id, a.name
)
SELECT m.title AS movie_title, 
       m.total_actors, 
       m.keywords, 
       COALESCE(amc.movie_count, 0) AS actor_movie_count,
       ah.level AS actor_depth
FROM movie_info_summary m
LEFT JOIN actor_movie_counts amc ON amc.movie_count > 2
LEFT JOIN actor_hierarchy ah ON ah.actor_id IN (SELECT person_id FROM cast_info WHERE movie_id = m.movie_id)
WHERE m.total_actors >= 5
ORDER BY m.total_actors DESC, amc.movie_count DESC
LIMIT 100;
