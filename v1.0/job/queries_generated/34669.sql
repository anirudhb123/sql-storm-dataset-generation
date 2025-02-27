WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.id IS NOT NULL
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        ct.kind AS role_name
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN comp_cast_type ct ON c.person_role_id = ct.id
),
movie_key_info AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
    FROM
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY
        m.id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role_name,
    mk.keywords,
    mk.additional_info,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cd.actor_name) AS actor_rank
FROM
    movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN movie_key_info mk ON mh.movie_id = mk.movie_id
WHERE
    mh.production_year >= 2000
    AND (mk.keywords IS NOT NULL OR mk.additional_info IS NOT NULL)
ORDER BY
    mh.production_year DESC,
    mh.title,
    actor_rank;
