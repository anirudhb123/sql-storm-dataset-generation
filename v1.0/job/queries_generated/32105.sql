WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.depth < 3
),

top_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
    HAVING
        COUNT(DISTINCT ci.person_id) > 2
),

movie_info_details AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT mi.info) AS movie_infos,
        KM.keywords
    FROM
        top_movies tm
    LEFT JOIN
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN (
        SELECT
            mk.movie_id,
            STRING_AGG(DISTINCT k.keyword, ', ') as keywords
        FROM
            movie_keyword mk
        JOIN
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    ) KM ON KM.movie_id = tm.movie_id
    GROUP BY
        tm.movie_id, tm.title, tm.production_year
)

SELECT
    mid.movie_id,
    mid.title,
    mid.production_year,
    mid.movie_infos,
    COALESCE(mid.keywords, 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (ORDER BY mid.production_year DESC) AS ranking
FROM
    movie_info_details mid
ORDER BY
    mid.production_year DESC,
    mid.title
LIMIT 10;

-- Performance Benchmarking
-- Potential indices:
-- CREATE INDEX idx_movie_year ON aka_title (production_year);
-- CREATE INDEX idx_cast_movie ON cast_info (movie_id);
-- CREATE INDEX idx_movie_info ON movie_info (movie_id);
-- CREATE INDEX idx_keyword ON movie_keyword (movie_id, keyword_id);
