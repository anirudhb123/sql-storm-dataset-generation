WITH movie_actors AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.person_id, a.name
),
keyword_movies AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
production_info AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(info.info, 'N/A') AS movie_info
    FROM
        aka_title m
    LEFT JOIN
        movie_info info ON m.id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
)
SELECT
    m.title,
    m.production_year,
    ma.name AS actor_name,
    ma.movie_count,
    km.keywords
FROM
    production_info m
JOIN
    movie_actors ma ON m.movie_id = ma.person_id
LEFT JOIN
    keyword_movies km ON m.movie_id = km.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2020
    AND (ma.movie_count > 5 OR km.keywords IS NOT NULL)
ORDER BY
    m.production_year DESC, ma.movie_count DESC;
