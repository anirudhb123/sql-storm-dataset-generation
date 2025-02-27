WITH RECURSIVE movie_series AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.season_nr,
        mt.episode_nr
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'series')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ms.level + 1,
        mt.season_nr,
        mt.episode_nr
    FROM 
        aka_title mt
    INNER JOIN 
        movie_series ms ON mt.episode_of_id = ms.movie_id
),

cast_summary AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        COUNT(ci.id) AS roles_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ai.person_id, ai.movie_id
),

movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mt.info, '; ') AS movie_infos
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),

rating_summary AS (
    SELECT 
        title_id,
        AVG(rating) AS average_rating
    FROM 
        (SELECT 
            mi.movie_id AS title_id,
            COALESCE(i.info::float, 0) AS rating
        FROM 
            movie_info mi
        LEFT JOIN 
            (SELECT 
                movie_id, 
                info 
            FROM 
                movie_info
            WHERE 
                info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) i ON mi.movie_id = i.movie_id
        ) AS subquery
    GROUP BY 
        title_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    cs.roles_count,
    cs.roles,
    mis.movie_infos,
    rs.average_rating
FROM 
    aka_title m
LEFT JOIN 
    cast_summary cs ON m.id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON m.id = mis.movie_id
LEFT JOIN 
    rating_summary rs ON m.id = rs.title_id
WHERE 
    (m.production_year IS NOT NULL AND m.production_year >= 2000)
    AND (
        (cs.roles_count > 0 AND rs.average_rating IS NOT NULL)
        OR 
        (rs.average_rating IS NULL AND cs.roles_count > 5)
    )
ORDER BY 
    m.production_year DESC;
