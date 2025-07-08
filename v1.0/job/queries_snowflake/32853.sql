
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors_list
    FROM
        cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
movie_info_summary AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info = 'Duration' THEN mi.info END) AS duration,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre
    FROM
        movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    mh.title,
    mh.production_year,
    COALESCE(cs.actor_count, 0) AS total_actors,
    cs.actors_list,
    mis.rating,
    mis.duration,
    mis.genre,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS ranking
FROM
    movie_hierarchy mh
LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE
    mh.production_year >= 2000
    AND (mis.rating IS NOT NULL OR mis.genre IS NOT NULL)
ORDER BY
    mh.production_year DESC,
    mh.title;
