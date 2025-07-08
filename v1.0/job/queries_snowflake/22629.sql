
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS depth,
        NULL AS parent_title
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL
    UNION ALL
    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        mh.depth + 1 AS depth,
        mh.title AS parent_title
    FROM
        aka_title e
    JOIN
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
production_companies AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
combined AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        mh.parent_title,
        cd.actor_name,
        cd.role_name,
        cd.role_order,
        mk.keywords,
        pc.companies
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN
        movie_keywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        production_companies pc ON mh.movie_id = pc.movie_id
)
SELECT
    movie_id,
    title,
    production_year,
    depth,
    parent_title,
    actor_name,
    role_name,
    role_order,
    keywords,
    companies
FROM
    combined
WHERE
    (depth < 3 OR parent_title IS NOT NULL)
    AND (keywords IS NOT NULL OR companies IS NOT NULL)
ORDER BY
    production_year, depth, title;
