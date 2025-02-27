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
        at.id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM
        aka_title at
    JOIN
        movie_hierarchy mh ON at.episode_of_id = mh.movie_id
),
actor_cast AS (
    SELECT
        c.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.person_id, a.name
),
company_summary AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
movie_info_summary AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'description' THEN mi.info END) AS description,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(ac.movie_count, 0) AS actor_count,
    COALESCE(cs.company_count, 0) AS company_count,
    cs.company_names,
    mis.description,
    mis.budget
FROM
    movie_hierarchy mh
LEFT JOIN
    actor_cast ac ON mh.movie_id = ac.movie_id
LEFT JOIN
    company_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY
    mh.production_year DESC,
    mh.level ASC;
