
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        ranked_movies rm
    WHERE
        rm.rank <= 5
),
movie_keywords AS (
    SELECT
        tm.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        top_movies tm
    JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        tm.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE
        WHEN tm.cast_count > 10 THEN 'Large Cast'
        WHEN tm.cast_count > 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM
    top_movies tm
LEFT JOIN
    movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
