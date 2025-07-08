
WITH
    ranked_movies AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
        FROM
            aka_title t
        WHERE
            t.production_year IS NOT NULL
    ),
    cast_counts AS (
        SELECT
            c.movie_id,
            COUNT(c.person_id) AS num_cast_members
        FROM
            cast_info c
        GROUP BY
            c.movie_id
    ),
    nulls_check AS (
        SELECT
            m.movie_id,
            COALESCE(m.title, 'Unknown Title') AS movie_title,
            COALESCE(c.num_cast_members, 0) AS cast_member_count
        FROM
            ranked_movies m
        LEFT JOIN
            cast_counts c ON m.movie_id = c.movie_id
    ),
    filtered_movies AS (
        SELECT
            movie_id,
            movie_title,
            cast_member_count
        FROM
            nulls_check
        WHERE
            cast_member_count > 0 OR POSITION('Unknown' IN movie_title) > 0
    )
SELECT
    f.movie_id,
    f.movie_title,
    f.cast_member_count,
    k.keyword AS movie_keyword,
    COALESCE(c.name, 'No Company') AS company_name
FROM
    filtered_movies f
LEFT JOIN
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
WHERE
    f.cast_member_count > (SELECT AVG(cast_member_count) FROM filtered_movies)
ORDER BY
    f.movie_title ASC,
    f.cast_member_count DESC
LIMIT 50;
