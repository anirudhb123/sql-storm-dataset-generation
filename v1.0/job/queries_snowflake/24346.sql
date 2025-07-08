
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS INTEGER) AS parent_id
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.movie_id
    FROM
        aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_with_ranks AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        a.name AS actor_name
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),
movies_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        k.keyword
    FROM
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),
company_info AS (
    SELECT
        mc.movie_id,
        LISTAGG(c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies,
        LISTAGG(ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    ci.companies,
    ci.company_types,
    MAX(cwr.actor_rank) AS max_actors,
    CASE
        WHEN MAX(cwr.actor_rank) > 0 THEN 'Active Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM
    movie_hierarchy mh
LEFT JOIN movies_with_keywords kw ON mh.movie_id = kw.movie_id
LEFT JOIN company_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN cast_with_ranks cwr ON mh.movie_id = cwr.movie_id
GROUP BY
    mh.movie_id,
    mh.title,
    mh.production_year,
    ci.companies,
    ci.company_types
HAVING
    COUNT(kw.keyword) > 5 OR MAX(cwr.actor_rank) IS NULL
ORDER BY
    mh.production_year DESC,
    mh.title ASC;
