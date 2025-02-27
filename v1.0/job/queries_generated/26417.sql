WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM
        aka_title ak
    JOIN
        title t ON ak.movie_id = t.id
    JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
high_cast_count_movies AS (
    SELECT
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        ranked_movies
    WHERE
        cast_count > 5
),
movie_info_details AS (
    SELECT
        m.movie_id,
        MIN(CASE WHEN i.info_type_id = 1 THEN i.info END) AS genre,
        MIN(CASE WHEN i.info_type_id = 2 THEN i.info END) AS language,
        MIN(CASE WHEN i.info_type_id = 3 THEN i.info END) AS production_company
    FROM
        movie_info m
    JOIN
        movie_info_idx i ON m.movie_id = i.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    h.movie_id,
    h.title,
    h.production_year,
    h.cast_count,
    h.aka_names,
    m.genre,
    m.language,
    m.production_company
FROM
    high_cast_count_movies h
LEFT JOIN
    movie_info_details m ON h.movie_id = m.movie_id
WHERE
    h.rank <= 10
ORDER BY
    h.cast_count DESC, h.production_year DESC;
