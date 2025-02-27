WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
selected_titles AS (
    SELECT 
        movie_id,
        title,
        actor_count
    FROM 
        ranked_movies
    WHERE 
        actor_count > 3
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    st.actor_count,
    COALESCE(st.actor_count, 0) AS adjusted_actor_count,
    CASE 
        WHEN st.actor_count IS NULL THEN 'No actors'
        ELSE 'Has actors'
    END AS actor_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    selected_titles st ON mh.movie_id = st.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.level ASC, mh.title;
