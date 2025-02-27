WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        aka_title AS mt
    JOIN 
        movie_hierarchy AS mh ON mt.episode_of_id = mh.movie_id
),

cast_role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),

info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS combined_info,
        COUNT(mi.id) AS info_count
    FROM 
        movie_info AS mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(cast_summary.actor_count, 0) AS total_actors,
    COALESCE(i_summary.info_count, 0) AS total_info_entries,
    i_summary.combined_info,
    mh.depth
FROM 
    aka_title AS m
LEFT JOIN 
    cast_role_summary AS cast_summary ON m.id = cast_summary.movie_id
LEFT JOIN 
    info_summary AS i_summary ON m.id = i_summary.movie_id
LEFT JOIN 
    movie_hierarchy AS mh ON m.id = mh.movie_id OR mh.depth IS NULL
WHERE 
    m.production_year >= 2000 
    AND (m.kind_id = 1 OR m.kind_id = 2) 
    AND mh.depth < 3
ORDER BY 
    m.production_year DESC, 
    total_actors DESC 
LIMIT 100;