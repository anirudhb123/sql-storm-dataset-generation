
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),

cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

movie_remarks AS (
    SELECT 
        m.id AS movie_id, 
        STRING_AGG(DISTINCT COALESCE(m.note, 'No Comments'), '; ') AS remarks
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Remarks')
    GROUP BY 
        m.id
),

categorized_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        c.actor_count,
        c.role_count,
        COALESCE(mr.remarks, 'No Remarks') AS remarks,
        CASE 
            WHEN mh.level > 1 THEN 'Episode'
            ELSE 'Movie'
        END AS category
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        movie_remarks mr ON mh.movie_id = mr.movie_id
)

SELECT 
    cm.movie_id,
    cm.movie_title,
    cm.production_year,
    cm.actor_count,
    cm.role_count,
    cm.remarks,
    cm.category
FROM 
    categorized_movies cm
WHERE 
    cm.actor_count > 2 
    AND cm.category = 'Episode'
    AND cm.production_year >= (EXTRACT(YEAR FROM CURRENT_DATE) - 10)

ORDER BY 
    cm.production_year DESC, cm.movie_title ASC;
