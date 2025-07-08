
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS aliases
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN
        cast_info cc ON t.id = cc.movie_id
    LEFT JOIN
        aka_name a ON cc.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, cast_count DESC) AS rank
    FROM
        ranked_movies
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    tm.aliases
FROM
    top_movies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.keyword_count DESC, tm.cast_count DESC;
