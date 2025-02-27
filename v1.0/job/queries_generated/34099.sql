WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM title m
    WHERE m.season_nr IS NULL -- Top-level movies that are not episodes
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        MAX(mi.info) AS synopsis,
        COUNT(DISTINCT mi.info_type_id) AS info_types
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(cs.actor_count, 0) AS actor_count,
    COALESCE(cs.actor_names, 'No actors') AS actor_names,
    COALESCE(mis.synopsis, 'No synopsis available') AS synopsis,
    mis.info_types
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;
