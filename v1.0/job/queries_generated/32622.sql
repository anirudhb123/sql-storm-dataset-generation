WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM title m
    WHERE m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(i.info, 'No info available') AS info
    FROM title m
    LEFT JOIN movie_info i ON m.id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.level,
        m.production_year,
        cs.total_cast,
        CS.cast_members,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY m.production_year DESC) AS ranking
    FROM movie_hierarchy mh
    JOIN movie_info_summary m ON mh.movie_id = m.movie_id
    LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
)
SELECT 
    rm.level,
    rm.ranking,
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_members
FROM ranked_movies rm
WHERE rm.level <= 3
ORDER BY rm.level, rm.ranking;
