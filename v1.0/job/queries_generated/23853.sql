WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        h.movie_id AS parent_movie_id,
        h.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h 
    ON 
        e.episode_of_id = h.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT a.id) AS actor_count,
        SUM(COALESCE(substr(a.name, position(' ' IN a.name) + 1), '') <> '') AS non_empty_surname_count 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_info_combined AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS plot_summary,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS user_rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title
),
final_results AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COALESCE(cd.actor_count, 0) AS total_actors,
        COALESCE(cd.actor_names, '{}') AS actor_names,
        COALESCE(mic.plot_summary, 'N/A') AS plot_summary,
        COALESCE(mic.user_rating, 'No rating') AS user_rating,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info_combined mic ON mh.movie_id = mic.movie_id
)
SELECT 
    f.movie_title,
    f.total_actors,
    f.actor_names,
    f.plot_summary,
    f.user_rating,
    CASE 
        WHEN f.level = 1 THEN 'Original Movie' 
        WHEN f.level > 1 THEN 'Episode'
        ELSE 'Unknown'
    END AS movie_type
FROM 
    final_results f
WHERE 
    f.total_actors > 0 
ORDER BY 
    f.movie_title ASC;
