WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        COALESCE(p.title, 'No Parent') AS parent_title,
        0 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN title p ON ml.linked_movie_id = p.id
    WHERE m.production_year = 2020

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.title AS parent_title,
        mh.level + 1
    FROM title m
    INNER JOIN movie_link ml ON m.id = ml.movie_id
    INNER JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),

unique_actors AS (
    SELECT 
        DISTINCT ak.id AS aka_id, 
        ak.name, 
        ak.person_id
    FROM aka_name ak
    INNER JOIN cast_info ci ON ak.person_id = ci.person_id
    INNER JOIN title t ON ci.movie_id = t.id
    WHERE ak.name IS NOT NULL
),

actor_movie_counts AS (
    SELECT 
        ua.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM unique_actors ua
    LEFT JOIN cast_info ci ON ua.person_id = ci.person_id
    GROUP BY ua.name
),

movie_keyword_info AS (
    SELECT 
        mt.movie_id, 
        k.keyword, 
        COUNT(mk.id) AS keyword_count
    FROM movie_keyword mk
    INNER JOIN keyword k ON mk.keyword_id = k.id
    INNER JOIN aka_title mt ON mk.movie_id = mt.movie_id
    WHERE mt.production_year BETWEEN 1990 AND 2000
    GROUP BY mt.movie_id, k.keyword
),

final_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(ak.actor_name, 'Unknown Actor') AS actor_name,
        COALESCE(mki.keyword, 'No Keywords') AS keyword,
        mh.level,
        (CASE 
            WHEN mh.level = 0 THEN 'Direct Movie'
            WHEN mh.level = 1 THEN 'First Link'
            ELSE 'Deeply Nested'
        END) AS depth_description,
        ak.movie_count
    FROM movie_hierarchy mh
    LEFT JOIN actor_movie_counts ak ON mh.movie_id = ak.movie_count
    LEFT JOIN movie_keyword_info mki ON mh.movie_id = mki.movie_id
    LEFT JOIN unique_actors ua ON mh.movie_id = ua.person_id
)
SELECT 
    movie_id,
    title,
    actor_name,
    keyword,
    level,
    depth_description,
    COALESCE(movie_count, 0) AS total_movies_with_actor
FROM final_result
WHERE level < 3 
AND (movie_count IS NULL OR movie_count >= 1)
ORDER BY title, level DESC;
