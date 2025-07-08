
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.kind_id = '1'  

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM
        aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

cast_details AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    INNER JOIN aka_name a ON ci.person_id = a.person_id
),

movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    INNER JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),

movies_with_info AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        LISTAGG(DISTINCT mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords,
        COUNT(cd.actor_name) AS actor_count
    FROM
        movie_hierarchy mh
    LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
)

SELECT
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.keywords,
    mw.actor_count,
    (SELECT AVG(actor_rank) FROM cast_details WHERE movie_id = mw.movie_id) AS avg_actor_rank,
    CASE
        WHEN mw.actor_count > 5 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_type
FROM
    movies_with_info mw
WHERE
    mw.production_year >= 2000
ORDER BY
    mw.actor_count DESC,
    mw.production_year ASC;
