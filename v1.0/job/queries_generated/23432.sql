WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS hierarchy_level,
        ARRAY[m.id] AS path
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1,
        path || m.id
    FROM
        aka_title m
    JOIN
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT
        c.person_id,
        COUNT(c.id) AS movie_count,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.person_id
),
role_distribution AS (
    SELECT
        r.id AS role_id,
        r.role,
        COUNT(c.id) AS count
    FROM
        role_type r
    LEFT JOIN
        cast_info c ON r.id = c.role_id
    GROUP BY
        r.id, r.role
),
keyword_counts AS (
    SELECT
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY
        m.id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.movie_count, 0) AS actor_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(rd.count, 0) AS role_distribution_count,
    CASE 
        WHEN mh.hierarchy_level > 0 THEN 'Episode'
        ELSE 'Feature'
    END AS movie_type,
    mh.path::text AS hierarchy_path
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_details cd ON cd.person_id = (SELECT person_id FROM cast_info WHERE movie_id = mh.movie_id LIMIT 1)
LEFT JOIN
    keyword_counts kc ON mh.movie_id = kc.movie_id
LEFT JOIN
    role_distribution rd ON rd.role_id IN (
        SELECT DISTINCT c.role_id 
        FROM cast_info c 
        WHERE c.movie_id = mh.movie_id
    )
WHERE
    mh.production_year > 2000
ORDER BY 
    mh.production_year DESC,
    movie_type,
    mh.title;
