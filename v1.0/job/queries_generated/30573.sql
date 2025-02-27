WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        m.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM
        aka_title m
    INNER JOIN
        movie_link ml ON m.id = ml.movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM
        movie_hierarchy mh
    INNER JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
),
actor_movie_counts AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    GROUP BY
        c.person_id
),
average_movie_per_actor AS (
    SELECT
        AVG(movie_count) as avg_movies
    FROM
        actor_movie_counts
),
full_actor_info AS (
    SELECT
        ak.id AS actor_id,
        ak.name,
        am.movie_count,
        a.avg_movies,
        CASE 
            WHEN am.movie_count > a.avg_movies THEN 'Above Average'
            WHEN am.movie_count < a.avg_movies THEN 'Below Average'
            ELSE 'Average'
        END AS performance_category
    FROM
        aka_name ak
    LEFT JOIN
        actor_movie_counts am ON ak.person_id = am.person_id
    CROSS JOIN
        average_movie_per_actor a
)
SELECT
    f.movie_id,
    f.title AS movie_title,
    f.level AS hierarchy_level,
    f.parent_id AS parent_movie_id,
    ai.actor_id,
    ai.name AS actor_name,
    ai.movie_count,
    ai.performance_category
FROM
    movie_hierarchy f
LEFT JOIN
    full_actor_info ai ON f.movie_id IN (
        SELECT DISTINCT c.movie_id
        FROM cast_info c
        WHERE c.person_id IN (SELECT actor_id FROM full_actor_info)
    )
WHERE
    f.level <= 2
ORDER BY
    f.hierarchy_level, f.movie_id, ai.movie_count DESC;

