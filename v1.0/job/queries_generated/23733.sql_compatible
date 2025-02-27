
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        ARRAY[t.id] AS path
    FROM aka_title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        mt.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        path || mt.linked_movie_id
    FROM movie_link mt
    JOIN movie_hierarchy mh ON mt.movie_id = mh.movie_id
    JOIN aka_title t ON mt.linked_movie_id = t.id
    WHERE NOT mt.linked_movie_id = ANY(mh.path) AND mh.level < 3
),
actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title m ON c.movie_id = m.id
),
latest_movies AS (
    SELECT 
        ami.actor_id, 
        ami.actor_name,
        mh.title,
        mh.production_year,
        mh.level
    FROM actor_movie_info ami
    JOIN movie_hierarchy mh ON ami.movie_id = mh.movie_id
    WHERE ami.rn = 1
)
SELECT 
    lm.actor_id,
    lm.actor_name,
    STRING_AGG(DISTINCT lm.title, ', ') AS titles,
    COUNT(DISTINCT lm.title) AS movie_count,
    MAX(lm.production_year) AS latest_year,
    MIN(lm.production_year) AS earliest_year,
    CASE 
        WHEN COUNT(DISTINCT lm.title) > 0 THEN 
            CAST((MAX(lm.production_year) - MIN(lm.production_year)) AS TEXT) || ' years'
        ELSE 'No movies'
    END AS production_span
FROM latest_movies lm
GROUP BY lm.actor_id, lm.actor_name
HAVING COUNT(DISTINCT lm.title) > 2
ORDER BY movie_count DESC, lm.actor_name ASC
LIMIT 10;
