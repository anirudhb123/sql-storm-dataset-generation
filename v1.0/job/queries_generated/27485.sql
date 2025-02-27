WITH movie_stats AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title AS a
    JOIN
        movie_companies AS mc ON a.movie_id = mc.movie_id
    JOIN
        cast_info AS ca ON a.movie_id = ca.movie_id
    LEFT JOIN
        aka_name AS ak ON ca.person_id = ak.person_id
    LEFT JOIN
        movie_keyword AS mk ON a.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.id
),

top_movies AS (
    SELECT
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.actors,
        ms.keywords,
        RANK() OVER (ORDER BY ms.cast_count DESC) AS rank
    FROM
        movie_stats ms
)

SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords
FROM
    top_movies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.cast_count DESC;

This SQL query is designed for benchmarking string processing by providing details of the top 10 movies based on the number of distinct cast members. It aggregates actor names and keywords associated with each movie while leveraging Common Table Expressions (CTEs) for clarity and efficiency.
