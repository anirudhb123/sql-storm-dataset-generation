WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        mhl.linked_movie_id,
        at.title,
        mhl.level + 1
    FROM
        movie_link mhl
    JOIN
        aka_title at ON mhl.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON mhl.movie_id = mh.movie_id
),
top_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        COUNT(ca.id) AS cast_count
    FROM
        movie_hierarchy mh
    JOIN
        cast_info ca ON mh.movie_id = ca.movie_id
    GROUP BY
        mh.movie_id, mh.title
    HAVING
        COUNT(ca.id) > 2
),
movie_keywords AS (
    SELECT
        mt.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mt.id
),
detailed_movies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.cast_count,
        COALESCE(mk.keywords, ARRAY[]::text[]) AS keywords
    FROM
        top_movies tm
    LEFT JOIN
        movie_keywords mk ON tm.movie_id = mk.movie_id
),
final_output AS (
    SELECT
        dm.movie_id,
        dm.title,
        dm.cast_count,
        dm.keywords,
        ROW_NUMBER() OVER (PARTITION BY dm.cast_count ORDER BY dm.cast_count DESC) AS rank
    FROM
        detailed_movies dm
    WHERE
        dm.cast_count >= 5
)
SELECT
    fo.movie_id,
    fo.title,
    fo.cast_count,
    fo.keywords,
    CASE 
        WHEN fo.keywords IS NULL OR ARRAY_LENGTH(fo.keywords, 1) = 0 THEN 'No keywords'
        ELSE 'Keywords available'
    END AS keyword_status
FROM
    final_output fo
WHERE
    fo.rank <= 10
ORDER BY
    fo.cast_count DESC, fo.title;
