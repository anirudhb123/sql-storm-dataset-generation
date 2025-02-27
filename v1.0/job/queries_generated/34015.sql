WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        mh.movie_id,
        CONCAT(mh.title, ' / ', t.title) AS title,
        t.production_year,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
    WHERE
        mh.level < 3
),
cast_member AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        cast_info ci
    INNER JOIN
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN
        role_type r ON ci.role_id = r.id
),
movie_info_filtered AS (
    SELECT
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'rating' THEN mi.info ELSE NULL END, ', ') AS ratings,
        COUNT(CASE WHEN mi.info IS NOT NULL THEN 1 END) AS info_count
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
    ARRAY_AGG(DISTINCT cm.actor_name) AS cast_members,
    mf.ratings,
    mf.info_count,
    COUNT(DISTINCT c.id) FILTER (WHERE c.id IS NOT NULL) AS total_cast
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_member cm ON mh.movie_id = cm.movie_id
LEFT JOIN
    movie_info_filtered mf ON mh.movie_id = mf.movie_id
LEFT JOIN
    complete_cast c ON mh.movie_id = c.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mf.ratings, mf.info_count
ORDER BY
    mh.production_year DESC, mh.title
LIMIT 10;
