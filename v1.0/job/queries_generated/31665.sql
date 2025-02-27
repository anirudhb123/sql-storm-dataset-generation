WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS integer) AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.movie_id AS parent_movie_id,
        h.level + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS performance_order
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
),
movie_statistics AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ac.actor_id) AS actor_count,
        STRING_AGG(DISTINCT ad.name, ', ') AS actors,
        MAX(mk.keyword) AS top_keyword
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        actor_details ad ON ad.actor_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
top_movies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.actor_count,
        ms.top_keyword,
        RANK() OVER (ORDER BY ms.actor_count DESC) AS rank
    FROM 
        movie_statistics ms
)
SELECT 
    tm.rank,
    tm.title,
    tm.actor_count,
    tm.top_keyword,
    CASE 
        WHEN tm.actor_count > 5 THEN 'High'
        WHEN tm.actor_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS actor_density,
    CASE 
        WHEN (SELECT COUNT(*) FROM aka_title WHERE production_year = 2023) > 0 THEN '2023 releases present'
        ELSE 'No 2023 releases'
    END AS recent_release_status
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
