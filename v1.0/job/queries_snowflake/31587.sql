
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

cast_movies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),

movie_ratings AS (
    SELECT 
        movie_id,
        AVG(CAST(info AS FLOAT)) AS average_rating
    FROM 
        movie_info
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        movie_id
),

selected_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COALESCE(mr.average_rating, 0) AS average_rating
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_ratings mr ON mh.movie_id = mr.movie_id
    WHERE 
        mh.level = 1
)

SELECT 
    sm.movie_title,
    sm.average_rating,
    LISTAGG(cm.actor_name, ', ') WITHIN GROUP (ORDER BY cm.actor_name) AS actors,
    CASE 
        WHEN sm.average_rating >= 8 THEN 'Excellent'
        WHEN sm.average_rating BETWEEN 5 AND 7 THEN 'Average'
        ELSE 'Poor'
    END AS rating_category
FROM 
    selected_movies sm
LEFT JOIN 
    cast_movies cm ON sm.movie_id = cm.movie_id
GROUP BY 
    sm.movie_id, sm.movie_title, sm.average_rating
ORDER BY 
    sm.average_rating DESC;
