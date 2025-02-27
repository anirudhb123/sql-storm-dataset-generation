WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
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
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
movie_info_summary AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Description' THEN mi.info END) AS description,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM
        movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast') AS cast_names,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    COALESCE(mis.description, 'No Description') AS description,
    COALESCE(mis.rating, 'No Rating') AS rating,
    mh.level
FROM
    movie_hierarchy mh
LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY
    mh.production_year DESC, mh.level, mh.title;
