
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS depth,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        mh.depth + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
),
ranked_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        amc.movie_count,
        RANK() OVER (ORDER BY amc.movie_count DESC) AS rank
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_count amc ON a.person_id = amc.person_id
),
movie_info_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id AS movie_id,
    mh.title AS movie_title,
    mh.depth AS movie_depth,
    ra.actor_id,
    ra.name AS actor_name,
    ra.movie_count AS total_movies,
    mw.keywords AS movie_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    ranked_actors ra ON cc.subject_id = ra.actor_id
LEFT JOIN 
    movie_info_with_keywords mw ON mh.movie_id = mw.movie_id
WHERE 
    (mh.depth < 2 OR ra.movie_count IS NOT NULL)
ORDER BY 
    mh.depth, ra.movie_count DESC
LIMIT 100;
