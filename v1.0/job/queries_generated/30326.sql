WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        NULL::INTEGER AS parent_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.episode_of_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),

cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        ae.title AS episode_title,
        mh.level
    FROM 
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
    LEFT JOIN aka_title ae ON mh.parent_id = ae.id
),

aggregated_data AS (
    SELECT 
        cd.movie_id,
        STRING_AGG(DISTINCT cd.actor_name, ', ') AS actor_names,
        MAX(cd.nr_order) AS last_order,
        COUNT(cd.actor_name) AS total_actors,
        MAX(CASE WHEN cd.level = 0 THEN cd.episode_title END) AS main_episode
    FROM 
        cast_details cd
    GROUP BY 
        cd.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    ad.actor_names,
    ad.total_actors,
    COALESCE(ad.main_episode, 'N/A') AS main_episode_title
FROM 
    aka_title m
JOIN 
    aggregated_data ad ON m.id = ad.movie_id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, ad.total_actors DESC;
