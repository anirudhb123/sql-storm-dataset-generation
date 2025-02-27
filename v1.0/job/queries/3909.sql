WITH ranked_movies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        title_id, title, production_year, cast_count
    FROM
        ranked_movies
    WHERE
        rn <= 5
),
keyword_summary AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM
    top_movies tm
LEFT JOIN
    keyword_summary ks ON tm.title_id = ks.movie_id
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
