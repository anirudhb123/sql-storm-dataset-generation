
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 0 AS level
    FROM aka_title m
    WHERE m.production_year = 2022  

    UNION ALL

    SELECT m.id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3  
),

top_roles AS (
    SELECT c.movie_id, c.role_id, COUNT(c.id) AS role_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, c.role_id
    HAVING COUNT(c.id) > 2  
),

popular_movies AS (
    SELECT mh.movie_id, mh.title, COUNT(DISTINCT c.person_id) AS actor_count
    FROM movie_hierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
    GROUP BY mh.movie_id, mh.title
    HAVING COUNT(DISTINCT c.person_id) > 5  
),

movies_with_keywords AS (
    SELECT m.id AS movie_id, ARRAY_AGG(k.keyword) AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),

final_results AS (
    SELECT pm.movie_id, pm.title, pm.actor_count, mk.keywords
    FROM popular_movies pm
    LEFT JOIN movies_with_keywords mk ON pm.movie_id = mk.movie_id
)

SELECT fr.title,
       fr.actor_count,
       COALESCE(STRING_AGG(DISTINCT fr.keywords::text, ', '), 'No keywords') AS keywords,
       CASE WHEN fr.actor_count > 10 THEN 'Highly Popular' ELSE 'Moderately Popular' END AS popularity_level
FROM final_results fr
GROUP BY fr.movie_id, fr.title, fr.actor_count
ORDER BY fr.actor_count DESC, fr.title
LIMIT 10;
