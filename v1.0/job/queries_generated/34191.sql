WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.season_nr IS NULL

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mh.production_year,
        mh.depth + 1
    FROM
        movie_hierarchy mh
    JOIN
        aka_title mt ON mh.movie_id = mt.episode_of_id
),

movie_info_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        mk.keyword,
        min(mk.keyword) OVER (PARTITION BY m.id) AS first_keyword
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
),

cast_info_summary AS (
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
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mk.keyword AS movie_keyword,
    ci.total_cast,
    ci.cast_names,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mh.movie_id 
       AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_info_with_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    cast_info_summary ci ON mh.movie_id = ci.movie_id
WHERE
    mh.production_year >= 2000
    AND (mk.first_keyword IS NULL OR mk.first_keyword != 'Action')
ORDER BY
    mh.production_year DESC,
    ci.total_cast DESC
LIMIT 100;

