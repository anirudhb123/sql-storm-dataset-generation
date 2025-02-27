WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title AS movie_title,
        ak.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title ak ON ak.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
actor_movie AS (
    SELECT 
        a.name,
        a.person_id,
        m.movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    JOIN aka_title m ON m.id = ci.movie_id
),
top_actors AS (
    SELECT 
        name,
        person_id
    FROM actor_movie
    WHERE rn = 1
),
movie_details AS (
    SELECT 
        m.movie_title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(c.person_id) AS actor_count
    FROM movie_hierarchy m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN cast_info c ON c.movie_id = m.movie_id
    GROUP BY m.movie_title, m.production_year, k.keyword
    HAVING COUNT(c.person_id) > 0
)
SELECT 
    md.movie_title,
    md.production_year,
    md.keyword,
    md.actor_count,
    t.name AS top_actor
FROM movie_details md
LEFT JOIN top_actors t ON md.actor_count > 3 AND t.name IN (
    SELECT DISTINCT a.name
    FROM aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    JOIN aka_title m ON m.id = ci.movie_id
    WHERE a.person_id IS NOT NULL AND m.production_year <= 2023
)
WHERE md.actor_count >= 5
ORDER BY md.production_year DESC, md.actor_count DESC
FETCH FIRST 10 ROWS ONLY;
