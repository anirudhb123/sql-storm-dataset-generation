WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, cast_details AS (
    SELECT
        c.id AS cast_id,
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.name) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title at ON c.movie_id = at.id
    WHERE
        at.production_year IS NOT NULL
)
, movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    cd.actor_rank
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE
    mh.level = 1
ORDER BY
    mh.production_year DESC,
    cd.actor_rank ASC
LIMIT 100;
