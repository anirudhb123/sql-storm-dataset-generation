WITH recursive movie_hierarchy AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 0 AS level
    FROM title t
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT m.movie_id, t.title, t.production_year, mh.level + 1
    FROM movie_link m
    JOIN title t ON m.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON m.movie_id = mh.movie_id
    WHERE mh.level < 3
),
actor_movies AS (
    SELECT ak.name AS actor_name, t.title AS movie_title, t.production_year
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE ak.name IS NOT NULL
),
keyword_movies AS (
    SELECT t.id AS movie_id, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE 'Action%'
)
SELECT mh.movie_id, mh.title, mh.production_year, COUNT(DISTINCT am.actor_name) AS actor_count, ARRAY_AGG(DISTINCT km.keyword) AS keywords
FROM movie_hierarchy mh
LEFT JOIN actor_movies am ON mh.movie_id = am.movie_title
LEFT JOIN keyword_movies km ON mh.movie_id = km.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, actor_count DESC;
