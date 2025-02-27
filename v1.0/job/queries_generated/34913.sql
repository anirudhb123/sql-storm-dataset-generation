WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        1 AS level,
        NULL AS parent_id
    FROM title m
    WHERE m.episode_of_id IS NULL -- Root movies (not episodes)
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id, 
        e.title AS movie_title, 
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id -- Hierarchical self-join for episodes
),

actor_with_movie AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        c.movie_id,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS latest_movie
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id AND mi.info_type_id = 1 -- .info_type_id = 1 might represent "rating"
    WHERE mi.info IS NOT NULL -- Only movies with ratings
),

company_movies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE c.country_code IS NOT NULL
),

ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(DISTINCT c.company_id) AS company_count,
        COALESCE(AVG(CAST(mi.info AS FLOAT)), 0) AS avg_rating -- Assuming info is numeric
    FROM movie_hierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN company_movies c ON c.movie_id = mh.movie_id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = 1
    GROUP BY mh.movie_id, mh.movie_title
)

SELECT 
    r.movie_id,
    r.movie_title,
    r.company_count,
    r.avg_rating,
    a.actor_name,
    a.latest_movie
FROM ranked_movies r
JOIN actor_with_movie a ON r.movie_id = a.movie_id
WHERE r.company_count > 1 
AND a.latest_movie = 1
ORDER BY r.avg_rating DESC, r.movie_title ASC
OFFSET 0 LIMIT 10;
