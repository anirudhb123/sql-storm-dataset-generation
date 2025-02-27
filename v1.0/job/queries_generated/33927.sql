WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year > 2000
    UNION ALL
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM
        movie_hierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
),
name_counts AS (
    SELECT
        a.name,
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name a
    INNER JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.name, a.person_id
    HAVING
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    nc.name AS notable_actor,
    nc.movie_count
FROM
    ranked_movies rm
LEFT JOIN name_counts nc ON rm.total_cast > 10
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC, rm.total_cast DESC;

WITH movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
movie_info_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
    GROUP BY
        m.id, m.title, m.production_year
)
SELECT
    mi.movie_id,
    mi.title,
    mi.production_year,
    COALESCE(mi.keywords, 'No keywords available') AS keywords
FROM
    movie_info_with_keywords mi
WHERE
    mi.production_year >= (SELECT MIN(production_year) FROM aka_title)
    AND mi.movie_id IN (SELECT DISTINCT movie_id FROM complete_cast)

UNION ALL

SELECT
    'Booked Movie' AS movie_id,
    'Name Placeholder' AS title,
    NULL AS production_year,
    'N/A' AS keywords
FROM
    dual
WHERE
    NOT EXISTS (SELECT 1 FROM aka_title);

