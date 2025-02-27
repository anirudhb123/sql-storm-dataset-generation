
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        title t
    WHERE
        t.production_year >= 2000
),
TopRatedMovies AS (
    SELECT
        tm.title_id,
        tm.title,
        tm.production_year,
        COALESCE(AVG(CAST(mv.info AS FLOAT)), 0) AS average_rating
    FROM
        RankedMovies tm
    LEFT JOIN
        movie_info mv ON tm.title_id = mv.movie_id AND mv.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        tm.title_id, tm.title, tm.production_year
    HAVING
        COUNT(mv.info) > 2
),
RelatedMovies AS (
    SELECT
        ml.movie_id,
        t.title AS linked_title,
        COUNT(ml.linked_movie_id) AS link_count
    FROM
        movie_link ml
    JOIN
        title t ON ml.linked_movie_id = t.id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    GROUP BY
        ml.movie_id, t.title
    HAVING
        COUNT(ml.linked_movie_id) > 1
),
CastInfo AS (
    SELECT
        ci.movie_id,
        COUNT(ci.id) AS cast_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
)
SELECT
    tr.title,
    tr.production_year,
    tr.average_rating,
    rm.linked_title,
    COALESCE(ci.cast_count, 0) AS cast_count
FROM
    TopRatedMovies tr
LEFT JOIN
    RelatedMovies rm ON tr.title_id = rm.movie_id
LEFT JOIN
    CastInfo ci ON tr.title_id = ci.movie_id
WHERE
    tr.average_rating >= 7.5
ORDER BY
    tr.production_year DESC, tr.average_rating DESC
LIMIT 10;
