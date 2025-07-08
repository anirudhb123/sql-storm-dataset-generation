
WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        m.production_year,
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS alias_names
    FROM
        aka_title AS a
    JOIN
        title AS m ON a.movie_id = m.id
    LEFT JOIN
        cast_info AS c ON m.id = c.movie_id
    LEFT JOIN
        aka_name AS ak ON ak.person_id = c.person_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        a.title, m.production_year, m.id
),
top_movies AS (
    SELECT
        movie_title,
        production_year,
        cast_count,
        alias_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        ranked_movies
)
SELECT
    movie_title,
    production_year,
    cast_count,
    alias_names
FROM
    top_movies
WHERE
    rank <= 10
ORDER BY
    production_year DESC, cast_count DESC;
