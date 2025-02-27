
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id
    FROM
        aka_title e
    JOIN
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
top_movies AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
    HAVING
        COUNT(DISTINCT mk.keyword_id) > 5
),
cast_stats AS (
    SELECT
        c.movie_id,
        c.role_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_members
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    GROUP BY
        c.movie_id, c.role_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(ts.keyword_count, 0) AS keyword_count,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC, COALESCE(cs.total_cast, 0) DESC) AS rank
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN
        top_movies ts ON mh.movie_id = ts.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.keyword_count,
    rm.rank,
    COALESCE(cn.kind, 'Unknown') AS company_type
FROM
    ranked_movies rm
LEFT JOIN
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN
    company_type cn ON mc.company_type_id = cn.id
WHERE
    rm.rank <= 10
ORDER BY
    rm.production_year DESC, rm.rank;
