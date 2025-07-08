
WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id AS actor_id, 
           c.name AS actor_name, 
           1 AS level 
    FROM cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2020)
    
    UNION ALL
    
    SELECT ci.person_id AS actor_id, 
           c.name AS actor_name, 
           ah.level + 1 
    FROM cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    JOIN actor_hierarchy ah ON ci.movie_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = ah.actor_id
    )
    WHERE ah.level < 3
),
movie_stats AS (
    SELECT m.id AS movie_id,
           m.title,
           COUNT(DISTINCT ci.person_id) AS actor_count,
           LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_list,
           SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS info_count,
           ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title
),
actor_performance AS (
    SELECT ah.actor_id,
           ah.actor_name,
           COUNT(DISTINCT ms.movie_id) AS movies_count,
           AVG(ms.actor_count) AS avg_actors_per_movie,
           MAX(ms.actor_count) AS max_actors_in_a_movie,
           MIN(ms.actor_count) AS min_actors_in_a_movie
    FROM actor_hierarchy ah
    LEFT JOIN movie_stats ms ON ah.actor_id = ms.actor_count
    GROUP BY ah.actor_id, ah.actor_name
)
SELECT ap.actor_name,
       ap.movies_count,
       ap.avg_actors_per_movie,
       ap.max_actors_in_a_movie,
       ap.min_actors_in_a_movie,
       CASE 
           WHEN ap.movies_count > 10 THEN 'Prolific Actor'
           WHEN ap.avg_actors_per_movie < 5 THEN 'Less Collaborative Actor'
           ELSE 'Average Actor'
       END AS actor_category
FROM actor_performance ap
WHERE ap.movies_count > 0
ORDER BY ap.movies_count DESC
LIMIT 20;
