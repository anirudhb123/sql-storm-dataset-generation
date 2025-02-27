WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM
        aka_title mt
    JOIN
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        aks.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_number
    FROM
        cast_info ci
    JOIN
        aka_name aks ON ci.person_id = aks.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
title_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.level AS hierarchy_level
    FROM
        title t
    LEFT JOIN
        movie_keywords mk ON t.id = mk.movie_id
    LEFT JOIN
        movie_hierarchy mh ON t.id = mh.movie_id
)
SELECT
    td.title_id,
    td.title,
    td.production_year,
    td.keywords,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    cd.role,
    cd.role_number,
    COUNT(cd.person_id) OVER (PARTITION BY td.title_id) AS total_cast,
    mh.parent_id
FROM
    title_details td
LEFT JOIN
    cast_details cd ON td.title_id = cd.movie_id
LEFT JOIN
    movie_hierarchy mh ON td.title_id = mh.movie_id
WHERE
    td.production_year >= 2000
    AND (cd.role IS NOT NULL OR cd.actor_name IS NOT NULL)
ORDER BY
    td.production_year DESC,
    td.title;
