WITH PopularGenres AS (
    SELECT
        kt.kind AS genre,
        COUNT(mt.id) AS movie_count
    FROM
        kind_type kt
    JOIN
        aka_title mt ON mt.kind_id = kt.id
    GROUP BY
        kt.kind
    HAVING
        COUNT(mt.id) > 50
), MovieStats AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title mt
    JOIN
        kind_type kt ON mt.kind_id = kt.id
    LEFT JOIN
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN
        movie_keyword mw ON mw.movie_id = mt.id
    LEFT JOIN
        keyword kw ON kw.id = mw.keyword_id
    GROUP BY
        mt.id, mt.title, mt.production_year, kt.kind
)
SELECT
    ms.title,
    ms.production_year,
    ms.genre,
    ms.cast_count,
    ms.company_count,
    ms.keywords
FROM
    MovieStats ms
JOIN
    PopularGenres pg ON ms.genre = pg.genre
ORDER BY
    ms.production_year DESC, ms.cast_count DESC;
