WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT
        m1.id,
        m1.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m1 ON ml.linked_movie_id = m1.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
company_info AS (
    SELECT
        c.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.country_code = 'USA'
),
character_names AS (
    SELECT
        c.imdb_index,
        c.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        char_name c
    LEFT JOIN
        cast_info ci ON c.imdb_id = ci.person_id
    GROUP BY
        c.imdb_index, c.name
    HAVING
        COUNT(DISTINCT ci.movie_id) > 5
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.title) AS rank
    FROM
        movie_hierarchy mh
)

SELECT
    rm.title,
    rm.rank,
    ci.company_name,
    ci.company_type,
    cn.name AS character_name,
    cn.movie_count
FROM
    ranked_movies rm
LEFT JOIN
    company_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    character_names cn ON rm.title LIKE '%' || cn.name || '%'
WHERE
    (ci.company_name IS NOT NULL OR cn.name IS NOT NULL)
ORDER BY
    rm.rank, rm.title;
