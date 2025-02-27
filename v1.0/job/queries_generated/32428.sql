WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(NULL AS text) AS parent_title
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        c.movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.title AS parent_title
    FROM
        complete_cast c
    JOIN
        aka_title t ON c.movie_id = t.id
    JOIN
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),
movie_titles AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        RANK() OVER (PARTITION BY mh.parent_title ORDER BY mh.production_year DESC) AS rank
    FROM
        movie_hierarchy mh
),
top_movies AS (
    SELECT
        m.title,
        m.production_year,
        COALESCE(aka.name, 'Unknown') AS main_actor,
        COUNT(mk.keyword) AS keyword_count
    FROM
        movie_titles m
    LEFT JOIN
        complete_cast c ON m.movie_id = c.movie_id
    LEFT JOIN
        aka_name aka ON c.person_id = aka.person_id AND c.nr_order = 1
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    WHERE
        m.rank = 1
    GROUP BY
        m.title, m.production_year, aka.name
)
SELECT
    *,
    CASE
        WHEN keyword_count > 5 THEN 'Highly Keyworded'
        WHEN keyword_count BETWEEN 3 AND 5 THEN 'Moderately Keyworded'
        ELSE 'Sparsely Keyworded'
    END AS keyword_category
FROM
    top_movies
WHERE
    production_year >= 2000
ORDER BY
    production_year DESC, title;
