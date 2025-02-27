WITH movie_statistics AS (
    SELECT
        a.id AS movie_id,
        t.title AS movie_title,
        MIN(c.nr_order) AS first_cast_order,
        COUNT(DISTINCT cm.company_id) AS production_companies,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        aka_title t
    JOIN
        complete_cast c ON t.id = c.movie_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cm ON mc.company_id = cm.id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword kw ON mk.keyword_id = kw.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        a.id, t.title
),

cast_statistics AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT pn.name, ', ') AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name pn ON c.person_id = pn.person_id
    GROUP BY
        c.movie_id
)

SELECT
    ms.movie_id,
    ms.movie_title,
    ms.first_cast_order,
    ms.production_companies,
    ms.keyword_count,
    cs.total_cast_members,
    cs.cast_names
FROM
    movie_statistics ms
JOIN
    cast_statistics cs ON ms.movie_id = cs.movie_id
ORDER BY
    ms.production_companies DESC,
    cs.total_cast_members DESC;
