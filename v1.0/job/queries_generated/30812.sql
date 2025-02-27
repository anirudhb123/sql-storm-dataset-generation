WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year = 2023

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN movie_hierarchy AS mh ON ml.linked_movie_id = mh.movie_id
    JOIN aka_title AS m ON ml.movie_id = m.id
    WHERE 
        mh.depth < 5
), 
unique_cast AS (
    SELECT 
        DISTINCT c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id, a.name
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT uc.person_id) DESC) AS actor_rank
    FROM 
        movie_hierarchy AS mh
    JOIN 
        cast_info AS c ON mh.movie_id = c.movie_id
    JOIN 
        unique_cast AS uc ON c.person_id = uc.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
), 
avg_movie_keywords AS (
    SELECT 
        mk.movie_id,
        AVG(mk_count) AS avg_keyword_count
    FROM 
        (SELECT 
             movie_id, 
             COUNT(keyword_id) AS mk_count
         FROM 
             movie_keyword 
         GROUP BY 
             movie_id) AS mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    uc.actor_name,
    uc.movie_count,
    COALESCE(amk.avg_keyword_count, 0) AS avg_keyword_count,
    CASE 
        WHEN uc.movie_count > 5 THEN 'Prolific Actor'
        WHEN uc.movie_count = 0 THEN 'No Movies'
        ELSE 'Regular Actor'
    END AS actor_tier
FROM 
    ranked_movies AS t
JOIN 
    unique_cast AS uc ON t.movie_id = uc.person_id
LEFT JOIN 
    avg_movie_keywords AS amk ON t.movie_id = amk.movie_id
WHERE 
    t.actor_rank <= 3
    AND (t.production_year IS NULL OR t.production_year >= 2000)
ORDER BY 
    t.production_year DESC,
    uc.movie_count DESC;
