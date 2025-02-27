WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL 

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        aka_title mt
    JOIN
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords,
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
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast Available') AS cast_names,
    COALESCE(ks.total_keywords, 0) AS total_keywords,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    mh.level
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    keyword_summary ks ON mh.movie_id = ks.movie_id
ORDER BY
    mh.production_year DESC,
    mh.title;