WITH RECURSIVE movie_graph AS (
    SELECT m.id AS movie_id, m.title AS movie_title, 
           ARRAY[m.player_id] AS actor_ids, 
           1 AS depth
    FROM aka_title m
    JOIN cast_info c ON c.movie_id = m.id
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title AS movie_title, 
           ARRAY_APPEND(g.actor_ids, c.person_id) AS actor_ids, 
           g.depth + 1
    FROM aka_title m
    JOIN cast_info c ON c.movie_id = m.id
    JOIN movie_graph g ON g.movie_id = c.movie_id
    WHERE c.person_id <> ALL(g.actor_ids) AND g.depth < 3
),
top_movies AS (
    SELECT movie_id, 
           COUNT(DISTINCT actor_ids) AS actor_count
    FROM movie_graph
    GROUP BY movie_id
    ORDER BY actor_count DESC
    LIMIT 10
),
movie_details AS (
    SELECT m.id AS movie_id, m.title, 
           COALESCE(ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL), '{}') AS keywords,
           m.production_year
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY m.id
)
SELECT m.movie_title, 
       CASE 
           WHEN d.production_year IS NULL THEN 'Unknown Year'
           ELSE d.production_year::text
       END AS production_year,
       COALESCE(m.keywords, '{}') AS keywords,
       COUNT(DISTINCT a.person_id) FILTER (WHERE a.role_id IS NOT NULL) AS distinct_actors,
       ARRAY_AGG(DISTINCT DISTINCT a.name) AS actor_names
FROM top_movies tm
JOIN movie_details d ON d.movie_id = tm.movie_id
JOIN cast_info a ON a.movie_id = tm.movie_id
LEFT JOIN aka_name an ON an.person_id = a.person_id
GROUP BY m.movie_title, d.production_year
HAVING COUNT(DISTINCT a.person_id) > 5
ORDER BY COUNT(DISTINCT a.person_id) DESC, d.production_year DESC NULLS LAST;
